#!/usr/bin/env python

# Check the 'readme.txt' for install instructions
import boto.ec2.cloudwatch
from boto.ec2.cloudwatch.metric import Metric
import bottle
from ConfigParser import ConfigParser
from datetime import datetime, timedelta
import gviz_api
import logging
import logging.handlers
from nitro_api import NitroAPI
import operator
import os
import json
# depends on 'rocket' server

# conf file import if it exists
conf = ConfigParser({ # defaults
	'server_host':'0.0.0.0',
    'server_port':'80',
    'server_reloader':'False',
    'server_debug':'False',
    'aws_access_key':'',
	'aws_secret_key':''
})

# read in config if it exists
if os.path.exists("./server.conf"):
    conf.read("./server.conf")

# load the config options into variables
server_host = conf.get('DEFAULT', 'server_host')
server_port = int(conf.get('DEFAULT', 'server_port'))
server_reloader = True if conf.get('DEFAULT', 'server_reloader').lower().strip() == "true" else False
server_debug = True if conf.get('DEFAULT', 'server_debug').lower().strip() == "true" else False

aws_access_key = conf.get('DEFAULT', 'aws_access_key')
aws_secret_key = conf.get('DEFAULT', 'aws_secret_key')

# add server logging via the rocket server
log = logging.getLogger('Rocket')
if server_debug:
	log.setLevel(logging.DEBUG)
else:
	log.setLevel(logging.INFO)
log.addHandler(logging.handlers.RotatingFileHandler('server.log', maxBytes=51200, backupCount=1))


# the index page
@bottle.route('/')
@bottle.view('index')
def index():
	return dict()

@bottle.route('/netscaler_config')
def netscaler_config():
	#api = NitroAPI(host=host, username=username, password=password)

	tcp_multiplexing = None
	if bottle.request.query.tcp_multiplexing:
		tcp_multiplexing = bottle.request.query.tcp_multiplexing

	caching = None
	if bottle.request.query.caching:
		caching = bottle.request.query.caching

	compression = None
	if bottle.request.query.compression:
		compression = bottle.request.query.compression

	return dict({
		"tcp_multiplex":tcp_multiplexing,
		"caching":caching,
		"compression":compression
	})


@bottle.route('/loader_config')
def loader_config():
	jitter = None
	if bottle.request.query.jitter:
		jitter = bottle.request.query.jitter

	drop_packets = None
	if bottle.request.query.drop_packets:
		drop_packets = bottle.request.query.drop_packets

	tcp_latency = None
	if bottle.request.query.tcp_latency:
		tcp_latency = bottle.request.query.tcp_latency

	jitter_rate = None
	if bottle.request.query.jitter_rate:
		jitter_rate = bottle.request.query.jitter_rate

	packet_drop_rate = None
	if bottle.request.query.packet_drop_rate:
		packet_drop_rate = bottle.request.query.packet_drop_rate

	tcp_latency_rate = None
	if bottle.request.query.tcp_latency_rate:
		tcp_latency_rate = bottle.request.query.tcp_latency_rate

	return dict({
		"jitter":jitter,
		"drop_packets":drop_packets,
		"tcp_latency":tcp_latency,
		"jitter_rate":jitter_rate,
		"packet_drop_rate":packet_drop_rate,
		"tcp_latency_rate":tcp_latency_rate
	})


# get graphing data
@bottle.route('/get_data')
def get_data():
	if bottle.request.query.qs and bottle.request.query.tqx:
		request_id = bottle.request.query.tqx.split(':')[1]
		query = json.loads(bottle.request.query.qs)

		bottle.response.set_header('Content-Type', 'text/plain')
		return get_cloudwatch_data(query, request_id, aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)
	else:
		return ""


# show the log file
@bottle.route('/server/log')
def server_log():
	log_content = ""
	# first append the previous log if it exists
	try:
		with open('./server.log.1', 'r') as log_file:
			log_content = log_file.read()
	except:
		pass

	# then append the current log if it exists
	try:
		with open('./server.log', 'r') as log_file:
			log_content += log_file.read()
	except:
		pass

	return "<pre>"+log_content+"</pre>"


# serve a favicon.ico so the pages do not return a 404 for the /favicon.ico path in the browser.
@bottle.route('/favicon.ico')
def favicon():
    return bottle.static_file('favicon.ico', root='./images/')


# routing for static files on the webserver
@bottle.route('/static/<filepath:path>')
def server_static(filepath):
    return bottle.static_file(filepath, root='./')



def get_cloudwatch_data(cloudviz_query, request_id, aws_access_key_id=None, aws_secret_access_key=None):
	"""    
	CREDITS: 
	- Original concept/code is from 'cloudviz.py', written by 'Mike Babineau <mike@bizo.com>'
	- Checkout his code at: http://github.com/mbabineau/cloudviz

	Query CloudWatch and return the results in a Google Visualizations API-friendly format

	Arguments:
	`cloudviz_query` -- (dict) parameters and values to be passed to CloudWatch (see README for more information)
	`request_id` -- (int) Google Visualizations request ID passed as part of the "tqx" parameter
	"""
	## CloudWatch variables
	# The maximum number of datapoints CloudWatch will return for a given query
	CW_MAX_DATA_POINTS = 1440
	# The minimum allowable period
	CW_MIN_PERIOD = 60

	# Initialize data description, columns to be returned, and result set
	description = { "Timestamp": ("datetime", "Timestamp")}
	columns = ["Timestamp"]
	rs = []

	# Build option list
	opts = ['unit','metric','namespace','statistics','period', 'dimensions', 'prefix', 'start_time', 'end_time', 'calc_rate', 'region', 'range']

	# Set default parameter values
	qa = {
		'calc_rate': True,
		# 'period': 60,
		#'start_time': datetime.now() - timedelta(days=1),
		#'end_time': datetime.now(),
		'range': 24
	}

	# Set passed args
	for opt in opts:
		if opt in cloudviz_query: qa[opt] = cloudviz_query[opt]

	# Convert timestamps to datetimes if necessary
	for time in ['start_time','end_time']:
		if time in qa:
			if type(qa[time]) == str or type(qa[time]) == unicode: 
				qa[time] = datetime.strptime(qa[time].split(".")[0], '%Y-%m-%dT%H:%M:%S')

	# If both start_time and end_time are specified, do nothing.  
	if 'start_time' in qa and 'end_time' in qa:
		pass
	# If only one of the times is specified, fill in the other based on range
	elif 'start_time' in qa and 'range' in qa:
		qa['end_time'] = qa['start_time'] + timedelta(hours=qa['range'])
	elif 'range' in qa and 'end_time' in qa:
		qa['start_time'] = qa['end_time'] - timedelta(hours=qa['range'])
	# If neither is specified, use range leading up to current time
	else:
		qa['end_time'] = datetime.now()
		qa['start_time'] = qa['end_time'] - timedelta(hours=qa['range'])

	# Parse, build, and run each CloudWatch query
	cloudwatch_opts = ['unit', 'metric', 'namespace', 'statistics', 'period', 'dimensions', 'prefix', 'calc_rate', 'region']
	for cloudwatch_query in cloudviz_query['cloudwatch_queries']:
		args = qa.copy()
		# Override top-level vars
		for opt in cloudwatch_opts:
			if opt in cloudwatch_query: args[opt] = cloudwatch_query[opt]

		# Calculate time range for period determination/sanity-check
		delta = args['end_time'] - args['start_time']
		delta_seconds = ( delta.days * 24 * 60 * 60 ) + delta.seconds + 1 #round microseconds up

		# Determine min period as the smallest multiple of 60 that won't result in too many data points
		min_period = 60 * int(delta_seconds / CW_MAX_DATA_POINTS / 60)
		if ((delta_seconds / CW_MAX_DATA_POINTS) % 60) > 0:
			min_period += 60

		if 'period' in qa:
			if args['period'] < min_period:
				args['period'] = min_period
		else:
			args['period'] = min_period

		# Make sure period isn't smaller than CloudWatch allows
		if args['period'] < CW_MIN_PERIOD: 
			args['period'] = CW_MIN_PERIOD

		# Defaulting AWS region to us-east-1
		if not 'region' in args: 
			args['region'] = 'us-east-1'

		# Use AWS keys if provided otherwise try to let boto figure it out.
		if aws_access_key_id and aws_secret_access_key:
			c = boto.ec2.cloudwatch.connect_to_region(args['region'], aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key, is_secure=False)
		else:
			try:
				c = boto.ec2.cloudwatch.connect_to_region(args['region'], is_secure=False)
			except:
				log.info("No AWS credentials found for boto.")
				bottle.abort(403, "No AWS credentials can be found.")
		
		# if the metric is a string, make it and prefix a list to reuse code...
		if isinstance(args['metric'], basestring): # is metric a string?
			args['metric'] = [args['metric']]
			args['prefix'] = [args['prefix']]

		# treat metric and prefix as lists...
		for i, metric in enumerate(args['metric']):
			# Pull data from EC2
			results = c.get_metric_statistics(args['period'], args['start_time'], args['end_time'], metric, args['namespace'], args['statistics'], args['dimensions'], args['unit'])

			# Format/transform results
			for d in results:
				# If desired, convert Sum to a per-second Rate
				if args['calc_rate'] == True and 'Sum' in args['statistics']: d.update({u'Rate': d[u'Sum']/args['period']})
				# Change key names
				keys = d.keys()
				keys.remove('Timestamp')
				for k in keys:
					key = args['prefix'][i]+k
					d[key] = d[k]
					del d[k]

			rs.extend(results)

			# Build data description and columns to be return
			description[args['prefix'][i]+'Samples'] = ('number', args['prefix'][i]+'Samples')
			description[args['prefix'][i]+'Unit'] = ('string', args['unit']) 
			for stat in args['statistics']:
				# If Rate is desired, update label accordingly
				if stat == 'Sum' and args['calc_rate'] == True:
					stat = 'Rate'
				description[args['prefix'][i]+stat] = ('number', args['prefix'][i]+stat)
				columns.append(args['prefix'][i]+stat)
	       

	# Sort data and present    
	data = sorted(rs, key=operator.itemgetter(u'Timestamp'))
	data_table = gviz_api.DataTable(description)
	data_table.LoadData(data)

	results = data_table.ToJSonResponse(columns_order=columns, order_by="Timestamp", req_id=request_id)
	return results



print "Reloader On: "+str(server_reloader)
if server_debug:
	print "Logging Level: DEBUG"
else:
	print "Logging Level: INFO"


# start the server.
bottle.run(server='rocket', host=server_host, port=server_port, reloader=server_reloader, debug=server_debug)
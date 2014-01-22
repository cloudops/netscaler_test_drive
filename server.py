#!/usr/bin/env python

# Check the 'readme.txt' for install instructions
import boto
import boto.ec2.cloudwatch
import bottle
from ConfigParser import ConfigParser
from datetime import datetime, timedelta
import gviz_api
import logging
import logging.handlers
from nitro_api import NitroAPI
import operator
import os
import paramiko
import pprint
import time
import json
import requests
# depends on 'rocket' server

# setup the conf object and set default values...
conf = ConfigParser()

conf.set('DEFAULT', 'discovered', 'False')

conf.set('DEFAULT', 'server_host', '0.0.0.0')
conf.set('DEFAULT', 'server_port', '80')
conf.set('DEFAULT', 'server_reloader', 'False')
conf.set('DEFAULT', 'server_debug', 'False')

conf.add_section('AWS')
conf.set('AWS', 'access_key', '')
conf.set('AWS', 'secret_key', '')
conf.set('AWS', 'region', 'us-east-1')

conf.add_section('NETSCALER')
conf.set('NETSCALER', 'active_profile', 'profile_1')
conf.set('NETSCALER', 'host', '')
conf.set('NETSCALER', 'user', 'nsroot')
conf.set('NETSCALER', 'pass', 'nsroot')
conf.set('NETSCALER', 'instance_id', '')
conf.set('NETSCALER', 'nsip', '')
conf.set('NETSCALER', 'eip', '')
conf.set('NETSCALER', 'mip', '')
conf.set('NETSCALER', 'vip', '')

load_generators = ['load_gen']
conf.add_section('LOADGENERATOR')
for lg in load_generators:
	conf.set('LOADGENERATOR', lg+'_id', '')
	conf.set('LOADGENERATOR', lg+'_ip', '')

webservers = ['web1', 'web2']
conf.add_section('WEBSERVERS')
for ws in webservers:
	conf.set('WEBSERVERS', ws+'_id', '')
	conf.set('WEBSERVERS', ws+'_ip', '')


# read in config if it exists
if os.path.exists("./server.conf"):
    conf.read("./server.conf")

# add server logging via the rocket server
log = logging.getLogger('Rocket')
logging.getLogger('Rocket').propagate = False
if conf.getboolean('DEFAULT', 'server_debug'):
	log.setLevel(logging.DEBUG)
else:
	log.setLevel(logging.INFO)
log_handler = logging.handlers.RotatingFileHandler('server.log', maxBytes=51200, backupCount=1)
log_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
log.addHandler(log_handler)


# the index page
@bottle.route('/')
@bottle.view('index')
def index():
	# check config and see if i need to setup anything on first run...
	if not conf.getboolean('DEFAULT', 'discovered'):
		discover_environment()  # go and find the details of the environment and load it into conf...
		log.info(
			"\n\nSERVER CONFIG:\n--------------\n"+
			"\nNETSCALER:\n"+pprint.pformat(conf._sections['NETSCALER'])+"\n"+
			"\nLOADGENERATOR:\n"+pprint.pformat(conf._sections['LOADGENERATOR'])+"\n"+
			"\nWEBSERVERS:\n"+pprint.pformat(conf._sections['WEBSERVERS'])+"\n")

		# update build the deployment file based on the discovered config.
		if conf.get('NETSCALER', 'vip') and conf.get('WEBSERVERS', 'web1_ip') and conf.get('WEBSERVERS', 'web2_ip'):
			with open("ns_profiles/profile_deployment.xml", "wt") as fout:
				with open("ns_profiles/profile_deployment.xml.tpl", "rt") as fin:
					for line in fin:
						fout.write(line.replace('{{netscaler_vip}}', conf.get('NETSCALER', 'vip')).replace('{{webserver_1_ip}}', conf.get('WEBSERVERS', 'web1_ip')).replace('{{webserver_2_ip}}', conf.get('WEBSERVERS', 'web2_ip')))
			ns_ssh = ssh_client(conf.get('NETSCALER', 'host'), 22, conf.get('NETSCALER', 'user'), conf.get('NETSCALER', 'pass'))
			
			# fix the file permissions (as per a bug on the NS; Dec 2013)
			ns_stdin1, ns_stdout1, ns_stderr1 = ns_ssh.exec_command('shell "chmod ugo+w /nsconfig/nstemplates/applications"')
			ns_stdin2, ns_stdout2, ns_stderr2 = ns_ssh.exec_command('shell "chmod ugo+w /nsconfig/nstemplates/applications/deployment_files"')
			ns_stdin3, ns_stdout3, ns_stderr3 = ns_ssh.exec_command('shell "chmod go+x /flash/nsconfig"')

			## debugging example
			#log.info("stdout1: "+str(ns_stdout1.readlines()))
			#log.info("stderr1: "+str(ns_stderr1.readlines()))
			#log.info("stdout2: "+str(ns_stdout2.readlines()))
			#log.info("stderr2: "+str(ns_stderr2.readlines()))
			#log.info("stdout3: "+str(ns_stdout3.readlines()))
			#log.info("stderr3: "+str(ns_stderr3.readlines()))

			ns_sftp = ns_ssh.open_sftp()
			ns_sftp.put('ns_profiles/profile_1.xml', '/nsconfig/nstemplates/applications/profile_1.xml')
			ns_sftp.put('ns_profiles/profile_2.xml', '/nsconfig/nstemplates/applications/profile_2.xml')
			#ns_sftp.put('ns_profiles/profile_3.xml', '/nsconfig/nstemplates/applications/profile_3.xml')
			ns_sftp.put('ns_profiles/profile_deployment.xml', '/nsconfig/nstemplates/applications/deployment_files/profile_deployment.xml')

			ns_sftp.close()
			ns_ssh.close()
			
			with NitroAPI(host=conf.get('NETSCALER', 'host'), username=conf.get('NETSCALER', 'user'), password=conf.get('NETSCALER', 'pass'), logging=conf.getboolean('DEFAULT', 'server_debug')) as api:
				# setup the IP addresses for the VIP and the MIP
				if conf.get('NETSCALER', 'mip') and conf.get('NETSCALER', 'vip'):
					for ip_type in ['mip', 'vip']:
						payload = {
							'sessionid':api.session,
							'onerror':'rollback',
							'nsip': {
								'ipaddress':conf.get('NETSCALER', ip_type),
								'netmask':'255.255.0.0',
								'type':ip_type.upper()
							}
						}
						api.request('/config/nsip', payload)

			if conf.get('LOADGENERATOR', 'load_gen_ip') and conf.get('NETSCALER', 'vip'):
				lg_ssh = ssh_client(conf.get('LOADGENERATOR', 'load_gen_ip'), 22, username='ubuntu', key_filename='./creds/dddemotest.pem')
				lg_stdin1, lg_stdout1, lg_stderr1 = lg_ssh.exec_command('sudo su -; nohup /home/ubuntu/replay.sh '+conf.get('NETSCALER', 'vip')+' &')
				log.info("stdout1: "+str(lg_stdout1.readlines()))
				log.info("stderr1: "+str(lg_stderr1.readlines()))
				lg_ssh.close()
				log.info("Load Generator has been started...")
		else:
			log.info("The Netscaler VIP or the webserver IPs where not discovered.")
			conf.set('DEFAULT', 'discovered', 'false')
			log.info("Resetting to 'undiscovered' because of a discovery error...")
			bottle.redirect("/config_error")

	# configure the active profile on page load...
	profile = conf.get('NETSCALER', 'active_profile')
	with NitroAPI(host=conf.get('NETSCALER', 'host'), username=conf.get('NETSCALER', 'user'), password=conf.get('NETSCALER', 'pass'), logging=conf.getboolean('DEFAULT', 'server_debug')) as api:
		# try and blow away all the potential configs
		try:
			api.request('/config/application?args=appname:profile_1', method='DELETE')
			api.request('/config/application?args=appname:profile_2', method='DELETE')
			#api.request('/config/application?args=appname:profile_3', method='DELETE')
		except:
			pass

		# configure the active profile
		payload = {
			'sessionid':api.session,
			'onerror':'rollback',
			'application': {
				'appname':profile,
				'apptemplatefilename':profile+'.xml',
				'deploymentfilename':'profile_deployment.xml'
			}
		}
		api.request('/config/application?action=import', payload)

		# save the config
		payload = {
			'sessionid':api.session,
			'onerror':'rollback',
			'nsconfig': {}
		}
		api.request('/config/nsconfig?action=save', payload)

	return dict({
		'webservers':[
			{'name':'Web1', 'id':conf.get('WEBSERVERS', 'web1_id')},
			{'name':'Web2', 'id':conf.get('WEBSERVERS', 'web2_id')}
		],
		'profile':profile
	})


# config error page
@bottle.route('/config_error')
def config_error():
	return '<b>Error configuring the environment...</b><br/><br /><a href="mailto:support@citrix.com?subject=NetScaler Test Drive Error">Please email Citrix</a> the contents of the <a href="/log">server log</a>...'


@bottle.route('/apply_netscaler_profile')
def apply_netscaler_profile():
	profile = None
	if bottle.request.query.profile:
		profile = bottle.request.query.profile
		active_profile = conf.get('NETSCALER', 'active_profile')

		with NitroAPI(host=conf.get('NETSCALER', 'host'), username=conf.get('NETSCALER', 'user'), password=conf.get('NETSCALER', 'pass'), logging=conf.getboolean('DEFAULT', 'server_debug')) as api:
			# remove the current template so we can update the active profile
			try:
				api.request('/config/application?args=appname:'+active_profile, method='DELETE')
			except:
				pass

			# configure the active profile
			payload = {
				'sessionid':api.session,
				'onerror':'rollback',
				'application': {
					'appname':profile,
					'apptemplatefilename':profile+'.xml',
					'deploymentfilename':'profile_deployment.xml'
				}
			}
			update_config = api.request('/config/application?action=import', payload)
			if update_config != None and 'headers' in update_config:
				# success, so update the active profile
				conf.set('NETSCALER', 'active_profile', profile)
				#if profile == 'profile_3':
				#	fix_profile_3(api)
			else:
				# failed, so let the client know which profile is active
				profile = active_profile

			# save the config
			payload = {
				'sessionid':api.session,
				'onerror':'rollback',
				'nsconfig': {}
			}
			api.request('/config/nsconfig?action=save', payload)

	return dict({
		"result":profile
	})


## content switching is not supported by default when exporting and importing templates
## by default each rule will load balance across all servers
## here we change the rules to only point to their respective server
#def fix_profile_3(api):
#	lb_servers = api.request('/config/lbvserver')
#	rule_names = []
#	if 'lbvserver' in lb_servers:
#		for lbvs in lb_servers['lbvserver']:
#			if lbvs['name'].startswith('app_u_profile_3'):
#				rule_names.append(lbvs['name'])
#
#	if len(rule_names) > 0:
#		lb_bindings = []
#		for rule in rule_names:
#			rule_binding = api.request('/config/lbvserver_service_binding/'+rule)
#			if 'lbvserver_service_binding' in rule_binding:
#				for rb in rule_binding['lbvserver_service_binding']:
#					if rb['servicename'] not in lb_bindings:
#						lb_bindings.append(rb['servicename'])
#
#		if len(lb_bindings) > 0:
#			for rule in rule_names:
#				api.request('/config/lbvserver_service_binding/'+rule+'?args=servicename:'+lb_bindings.pop(0), method="DELETE")


@bottle.route('/netscaler_redirect')
@bottle.view('netscaler_redirect')
def netscaler_redirect():
	return dict({
		'ns_host':conf.get('NETSCALER', 'host'),
		'ns_user':conf.get('NETSCALER', 'user'),
		'ns_pass':conf.get('NETSCALER', 'pass')
	})


# get graphing data
@bottle.route('/get_data')
def get_data():
	if bottle.request.query.qs and bottle.request.query.tqx:
		request_id = bottle.request.query.tqx.split(':')[1]
		query = json.loads(bottle.request.query.qs)

		bottle.response.set_header('Content-Type', 'text/plain')
		return get_cloudwatch_data(query, request_id, aws_access_key_id=conf.get('AWS', 'access_key'), aws_secret_access_key=conf.get('AWS', 'secret_key'))
	else:
		return ""


# show the log file
@bottle.route('/log')
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


# get the cloudwatch data and return it in a format usable by google charts
def get_cloudwatch_data(cloudviz_query, request_id, aws_access_key_id=None, aws_secret_access_key=None):
	"""    
	CREDITS: 
	- Original concept/code is from 'cloudviz.py', written by 'Mike Babineau <mike@bizo.com>'
	- Checkout his code at: http://github.com/mbabineau/cloudviz

	Query CloudWatch and return the results in a Google Visualizations API-friendly format

	Arguments:
	'cloudviz_query' -- (dict) parameters and values to be passed to CloudWatch
	'request_id' -- (int) Google Visualizations request ID passed as part of the "tqx" parameter
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

		# If region is not passed, use the configured region
		args['region'] = conf.get('AWS', 'region')

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


def discover_environment():
	try:
		if conf.get('AWS', 'access_key') and conf.get('AWS', 'secret_key'):
			import os
			dashboard_instance_id = None # 'i-06abc632' #
			try:
				with os.popen("/opt/aws/bin/ec2-metadata") as f:
					for line in f:
						if line.startswith("instance-id:"):
							dashboard_instance_id = line.split(" ")[1].strip()
							log.info("Determined the control panel instance_id to be: "+dashboard_instance_id)
							break
			except: pass

			if dashboard_instance_id:
				log.info("Creating a connection with AWS on region: "+conf.get('AWS', 'region'))
				conn = boto.ec2.connect_to_region(conf.get('AWS', 'region'), aws_access_key_id=conf.get('AWS', 'access_key'), aws_secret_access_key=conf.get('AWS', 'secret_key'))
				log.info("Attempting to get data about the environment from AWS using the instance id")
				dashboard_instance = conn.get_only_instances([dashboard_instance_id])
				log.info("Determined the VPC ID to be: "+dashboard_instance[0].vpc_id)
				conf.set('DEFAULT', 'vpc_id', dashboard_instance[0].vpc_id)
				log.info("Getting all instances in the VPC")
				all_instances = conn.get_only_instances(filters={'vpc_id':dashboard_instance[0].vpc_id})
				lgs = load_generators
				wss = webservers
				for instance in all_instances:
					if instance.id == dashboard_instance_id or instance.state != 'running':
						continue # skip this instance...

					if instance.platform == 'windows': # its the NETSCALER and its running
						log.info("Found the NETSCALER with instance id '%s' and public ip '%s'" % (instance.id, instance.ip_address))
						conf.set('NETSCALER', 'instance_id', instance.id)
						conf.set('NETSCALER', 'host', instance.ip_address)
						conf.set('NETSCALER', 'eip', instance.ip_address)
						conf.set('NETSCALER', 'nsip', instance.private_ip_address)
						ns_ips = ['mip', 'vip']
						for ip_instance in instance.interfaces[0].private_ip_addresses:
							if ip_instance.private_ip_address != instance.private_ip_address:
								conf.set('NETSCALER', ns_ips.pop(0), ip_instance.private_ip_address)
					else:
						if len(lgs) > 0:
							log.info("Found the LOADGENERATOR with instance id '%s' and private ip '%s'" % (instance.id, instance.private_ip_address))
							load_generator = lgs.pop(0)
							conf.set('LOADGENERATOR', load_generator+'_id', instance.id)
							conf.set('LOADGENERATOR', load_generator+'_ip', instance.private_ip_address)
						else:
							if len(wss) > 0:
								log.info("Found a WEBSERVERS with instance id '%s' and private ip '%s'" % (instance.id, instance.private_ip_address))
								webserver = wss.pop(0)
								conf.set('WEBSERVERS', webserver+'_id', instance.id)
								conf.set('WEBSERVERS', webserver+'_ip', instance.private_ip_address)
				conf.set('DEFAULT', 'discovered', 'true')
				log.info("Finished initial discovery...")
			else:
				log.info("Failed to find the instance id, can't auto configure environment...")
				bottle.redirect("/config_error")
		else:
			log.info("AWS credentials have not been configured correctly...")
			bottle.redirect("/config_error")
	except Exception, e:
		log.exception(e)
		log.info("Environment discovery failed with an exception...")
		bottle.redirect("/config_error")


def ssh_client(server, port, username=None, password=None, key_filename=None):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    kwargs = {}
    if username:
    	kwargs['username'] = username
    if password:
    	kwargs['password'] = password
    if key_filename:
    	kwargs['key_filename'] = key_filename
    client.connect(server, port, **kwargs)
    return client


print "Reloader On: "+str(conf.getboolean('DEFAULT', 'server_reloader'))
if conf.getboolean('DEFAULT', 'server_debug'):
	print "Logging Level: DEBUG"
else:
	print "Logging Level: INFO"


# start the server.
bottle.run(
	server='rocket', 
	host=conf.get('DEFAULT', 'server_host'), 
	port=conf.getint('DEFAULT', 'server_port'), 
	reloader=conf.getboolean('DEFAULT', 'server_reloader'), 
	debug=conf.getboolean('DEFAULT', 'server_debug'))

INSTALL (FROM SCRATCH)
----------------------
# If you need to recreate the Control Panel AMI for some reason.
# These are the steps you would need to take.
(make sure python 2.7 is installed...)
$ yum install git (assuming that is how you get it to the machine)
$ yum install python-pip
$ pip install boto
$ pip install bottle
$ pip install paramiko
$ pip install rocket

$ curl -O https://google-visualization-python.googlecode.com/files/gviz_api_py-1.8.2.tar.gz
$ tar -xvf gviz_api_py-1.8.2.tar.gz
$ cd gviz_api_py-*
$ python setup.py install


start server.py at boot
-----------------------
$ vim /etc/rc.local
(add the following line at the end of the file according to the location of server.py)

cd /path/to/netscaler_test_drive; python server.py


configuration needed if building from scratch
---------------------------------------------
Modify the ssh key in './creds' so the server can ssh 
to other machines in the environment.

The key currently being referenced is 'dddemotest.pem' as: 'ssh -i ./creds/dddemotest.pem ...'

--- --- ---

You need to create a './server.conf' file with the following information.

[AWS]
access_key = <aws access key>
secret_key = <aws secret key>

You will also want to verify that the default settings configured in
'./server.py:24-57' are correct for your environment.

--- --- ---

If you implement the MEMORY USAGE functionality below,
you will also need the file: './creds/awscreds.template'

This file includes AWS credentials needed to push 
custom metrics to CloudWatch and is in the format:

AWSAccessKeyId=<aws access key>
AWSSecretKey=<aws secret key>



DISABLED BY DEFAULT due to NS bugs
----------------------------------
Currently there is only one profile configured.
However, three profiles are being sshed to the NetScaler.
We can not enable all 3 profiles because of bugs on the NS.
Once the bugs are fixed, enabling the 2 additional profiles 
is as easy as uncommenting the UI for them in 
'./views/index.tpl:225-234'



IMPLEMENTED but REQUIRES ADDITIONAL STEPS
-----------------------------------------
If you want MEMORY USAGE to be part of CloudWatch Metrics, 
do the following on each monitored (web server) instance:
(DOCS: http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-perl.html)

The creation of these graphs in the control panel is currently
commented out in the file 'views/index.tpl'.
Review the 'drawVisualizations()' function to enable.

On each web server you want to collect memory usage for, do the following:
(ubuntu: sudo apt-get install unzip libwww-perl libcrypt-ssleay-perl)
$ scp -i ~/.ssh/<ssh_key>.pem ./cron/CloudWatchMonitoringScripts-v1.1.0.zip ec2-user@<instance>:~/.
$ scp -i ~/.ssh/<ssh_key>.pem ./creds/awscreds.template ec2-user@<instance>:~/.
$ ssh -i ~/.ssh/<ssh_key>.pem ec2-user@<instance>
$ unzip CloudWatchMonitoringScripts-v1.1.0.zip
$ rm ./aws-scripts-mon/awscreds.template
$ mv ./awscreds.template ./aws-scripts-mon/
$ crontab -e
> */5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --from-cron --aws-credential-file=awscreds.template



ADDITIONAL NOTES AND WORK AROUND DOCS
-------------------------------------

--- --- ---

There are permission bugs on the NetScaler which require some  
changes to be done on the NetScaler prior to pushing the profiles.

This code is at: './server.py:101-104'
(commands documented here for completeness)
# fix the file permissions (as per a bug on the NS; Dec 2013)
stdin1, stdout1, stderr1 = ns_ssh.exec_command('shell "chmod ugo+w /nsconfig/nstemplates/applications"')
stdin2, stdout2, stderr2 = ns_ssh.exec_command('shell "chmod ugo+w /nsconfig/nstemplates/applications/deployment_files"')
stdin3, stdout3, stderr3 = ns_ssh.exec_command('shell "chmod go+x /flash/nsconfig"')

--- --- ---

The default and only profile currently loaded is the Content Switching profile.
Content switching is not supported by Application Templates as it
only supports the import of load balancing services.

The underlying Application Template functionality supports Content Switching,
but there is not support for the IMPORT functionality, which is how
we are managing the different profiles.

I have implemented a work around which removes a different service_binding
from each of the two load balanced rules after import in order to recreate the 
content switching functionality in the profile.  

This is implemented as 'profile_3' and requires the 'fix_profile_3()' function
to be run after profile_3 is imported.

This code is at: './server.py:250:272'

--- --- ---

The ability to graph more than one metric on a single graph
has been developed, but was not used.  This functinality is
enabled by passing the 'metric' and 'prefix' as an
arrays of strings instead of just strings.

To better understand this functionality, review the code at: 
Request sent from:  ./views/index.tpl:drawVisualizations()
Request handled at: ./server.py:444-476

--- --- ---


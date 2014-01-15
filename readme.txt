SSH
---
ssh -i ~/.ssh/swill_ec2.pem ec2-user@ec2-54-213-97-239.us-west-2.compute.amazonaws.com
ssh -i ~/.ssh/swill_ec2.pem ec2-user@54.200.202.196

through ns: http://54.200.21.62/


Setup and usage for the control panel...

INSTALL
-------
(make sure python 2.7 is installed...)
$ yum install git (if you will be pulling the repo)
$ yum install python-pip
$ pip install boto
$ pip install bottle
$ pip install paramiko
$ pip install requests
$ pip install rocket

$ curl -O http://xael.org/norman/python/python-nmap/python-nmap-0.1.4.tar.gz
$ tar -xvf python-nmap-0.3.2.tar.gz
$ cd python-nmap-*
$ python setup.py install
(install nmap on the control panel server as well)

$ curl -O https://google-visualization-python.googlecode.com/files/gviz_api_py-1.8.2.tar.gz
$ tar -xvf gviz_api_py-1.8.2.tar.gz
$ cd gviz_api_py-*
$ python setup.py install



If you want MEMORY USAGE to be part of CloudWatch Metrics, do the following on each instance:
(DOCS: http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-perl.html)
(ubuntu: sudo apt-get install unzip libwww-perl libcrypt-ssleay-perl)
$ scp -i ~/.ssh/<ssh_key>.pem ./cron/CloudWatchMonitoringScripts-v1.1.0.zip ec2-user@<instance>:~/.
$ scp -i ~/.ssh/<ssh_key>.pem ./creds/awscreds.template ec2-user@<instance>:~/.
$ ssh -i ~/.ssh/<ssh_key>.pem ec2-user@<instance>
$ unzip CloudWatchMonitoringScripts-v1.1.0.zip
$ rm ./aws-scripts-mon/awscreds.template
$ mv ./awscreds.template ./aws-scripts-mon/
$ crontab -e
> */5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --from-cron --aws-credential-file=awscreds.template
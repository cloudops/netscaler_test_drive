INSTALL
-------
(make sure python 2.7 is installed...)
$ yum install git (if you will be pulling the repo)
$ yum install python-pip
$ pip install boto
$ pip install bottle
$ pip install paramiko
$ pip install rocket

$ curl -O https://google-visualization-python.googlecode.com/files/gviz_api_py-1.8.2.tar.gz
$ tar -xvf gviz_api_py-1.8.2.tar.gz
$ cd gviz_api_py-*
$ python setup.py install



If you want MEMORY USAGE to be part of CloudWatch Metrics, do the following on each monitored (web server) instance:
(DOCS: http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-perl.html)

This section requires some additional code changes to uncomment the memory graphs in the 'views/index.tpl' file

(ubuntu: sudo apt-get install unzip libwww-perl libcrypt-ssleay-perl)
$ scp -i ~/.ssh/<ssh_key>.pem ./cron/CloudWatchMonitoringScripts-v1.1.0.zip ec2-user@<instance>:~/.
$ scp -i ~/.ssh/<ssh_key>.pem ./creds/awscreds.template ec2-user@<instance>:~/.
$ ssh -i ~/.ssh/<ssh_key>.pem ec2-user@<instance>
$ unzip CloudWatchMonitoringScripts-v1.1.0.zip
$ rm ./aws-scripts-mon/awscreds.template
$ mv ./awscreds.template ./aws-scripts-mon/
$ crontab -e
> */5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --from-cron --aws-credential-file=awscreds.template


EXTRAS
------
Currently there is only one profile configured, but 3 profiles are being placed on the NetScaler.  We currently can not enable all 3 profiles because of bugs on the NS.  Once the bugs are fixed, enabling the 2 additional profiles is as easy as uncommenting the UI for them in the 'views/index.tpl' file on lines 225 to 234.
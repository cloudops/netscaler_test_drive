SSH
---
ssh -i ~/.ssh/swill_ec2.pem ec2-user@ec2-54-213-97-239.us-west-2.compute.amazonaws.com


Setup and usage for the control panel...

INSTALL
-------
(make sure python 2.7 is installed...)
$ yum install git (if you will be pulling the repo)
$ yum install python-pip
$ pip install boto
$ pip install bottle
$ pip install rocket

$ curl -O https://google-visualization-python.googlecode.com/files/gviz_api_py-1.8.2.tar.gz
$ tar -xvf gviz_api_py-1.8.2.tar.gz
$ cd gviz_api_py-*
$ python setup.py install



If you want MEMORY USAGE to be part of CloudWatch Metrics, do the following on each instance:
(DOCS: http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-perl.html)
$ scp -i ~/.ssh/swill_ec2.pem ./cron/CloudWatchMonitoringScripts-v1.1.0.zip ec2-user@<instance>:~/.
$ scp -i ~/.ssh/swill_ec2.pem ./creds/awscreds.template ec2-user@<instance>:~/.
$ ssh -i ~/.ssh/swill_ec2.pem ec2-user@<instance>
$ unzip CloudWatchMonitoringScripts-v1.1.0.zip
$ rm ./aws-scripts-mon/awscreds.template
$ cp ./awscreds.template ./aws-scripts-mon/
$ crontab -e
> */5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --from-cron --aws-credential-file=awscreds.template
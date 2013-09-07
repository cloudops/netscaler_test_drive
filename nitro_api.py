#!/usr/bin/env python

# Author: Will Stevens - wstevens@cloudops.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import urllib
import urllib2
import json
import pprint

class NitroAPI(object):
    """
    Login and run queries against the Nitro API for NetScaler 9.2+.

    Basic Example (requires explicit logout):
    api = NitroAPI(host=host, username=username, password=password)
    api.request('/stat/system')
    api.request('/config', dict({'object': {'logout': {}}}))

    Example using WITH (to automatically logout):
    with NitroAPI(host=host, username='username', password='password') as api:
        api.request('/stat/system')
    
    """
    
    def __init__(self, protocol='http', host='127.0.0.1', uri='/nitro/v1', username=None, password=None, logging=True):        
        self.protocol = protocol
        self.host = host
        self.uri = uri
        self.username = username
        self.password = password
        self.session = None
        self.logging = logging
        self.errors = []
        
        # setup header handling
        self.opener = urllib2.build_opener()
        self.opener.addheaders.append(('Content-Type', 'application/x-www-form-urlencoded'))
        
        # login to get a session
        login_payload = dict({
            'object': {
                'login': {
                    'username':self.username,
                    'password':self.password
                }
            }
        })
        
        login_result = self.request('/config', login_payload)
        if login_result and 'sessionid' in login_result:
            self.session = login_result['sessionid']
            self.opener.addheaders.append(('Cookie', 'sessionid='+self.session))
        else:
            self.errors.append('Login failed...')
            print self.errors

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.request('/config', dict({'object': {'logout': {}}}))

    def end_session(self):
        for i, header in enumerate(self.opener.addheaders):
            if header[0] == 'Cookie' and header[1].startswith('sessionid'):
                del self.opener.addheaders[i]
                break

        
    def request(self, path, payload=None):
        """
        Builds the request and returns a json object of the result or None.
        If 'payload' is specified, the request will be a POST, otherwise it will be a GET.

        :param path: a path appended to 'self.uri' (default of '/nitro/v1'), eg: path='/config' => '/nitro/v1/config'
        :type path: str or unicode

        :param payload: the object to be POSTed
        :type payload: dict or None

        :returns: the result of the request as a dictionary
        :rtype: dict or None
        """
        if self.session or (self.username and self.password and payload and 'object' in payload and 'login' in payload['object']):
            output = None
            url = self.protocol+'://'+self.host+self.uri+path
            try:
                if payload:
                    response = self.opener.open(url, urllib.urlencode(payload))
                else:
                    response = self.opener.open(url)
                output = json.loads(response.read())

                if payload and 'object' in payload and 'logout' in payload['object']:
                    self.end_session()
            except urllib2.HTTPError, e:
                self.errors.append('HTTPError: '+str(e.code)+' - '+e.msg)
                print self.errors
            except urllib2.URLError, e:
                self.errors.append('URLError: '+str(e.reason))
                print self.errors
               
            if self.logging:
                with open('nitro_api.log', 'a') as f:
                    if payload:
                        f.write("POST "+url)
                        f.write('\n')
                        pprint.pprint(payload, f, 2)
                    else:
                        f.write("GET "+url)
                        f.write('\n')
                    f.write('\n')
                    f.write('response:\n')
                    if output:
                        pprint.pprint(output, f, 2)
                    else:
                        f.write(repr(self.errors))
                    f.write('\n\n\n\n')

            return output
        else:
            self.errors.append('missing credentials in the constructor')
            return None



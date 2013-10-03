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

import json
import pprint
import requests
import urlparse

class NitroAPI(object):
    """
    Login and run queries against the Nitro API for NetScaler 10.1.

    ## Basic Example (requires explicit logout):
    api = NitroAPI(host=host, username=username, password=password)
    api.request('/config/login', {
        'login': {
            'username':api.username,
            'password':api.password
        }
    })
    system_stats = api.request('/stat/system')
    api.request('/config/logout', {'logout': {}})

    ## Example using WITH (to automatically login and logout):
    with NitroAPI(host=host, username='username', password='password') as api:
        system_stats = api.request('/stat/system')
    
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

    def __enter__(self):
        # login to get a session
        self.request('/config/login', {
            'login': {
                'username':self.username,
                'password':self.password
            }
        })
        return self

    def __exit__(self, type, value, traceback):
        self.request('/config/logout', {'logout': {}})

    def end_session(self):
        self.session = None

    def get_req_name(self, path):
        _path = urlparse.urlparse(path).path
        if _path.endswith('/'): _path = _path[:-1]
        return _path.rsplit('/', 1)[1]

        
    def request(self, path, payload=None, method=None):
        """
        Builds the request and returns a json object of the result or None.
        If 'payload' is specified, the request will be a POST, otherwise it will be a GET.

        :param path: a path appended to 'self.uri' (default of '/nitro/v1'), eg: path='/config' => '/nitro/v1/config'
        :type path: str or unicode

        :param payload: the object to be passed to the server
        :type payload: dict or None

        :param method: the request method [ GET | POST | PUT | DELETE ]
        :type method: str or unicode

        :returns: the result of the request as a dictionary; 
            if result == '': return {'headers': <headers dict>}
            if result != json and result != '': return {'result': '<text returned>'}
        :rtype: dict or None
        """
        if self.session or (self.username and self.password and payload and 'login' in payload):
            result = None
            headers = {}
            cookies = {}

            url = self.protocol+'://'+self.host+self.uri+path
            if self.session:
                cookies['NITRO_AUTH_TOKEN'] = self.session

            if payload:
                if method and method.upper() == 'PUT':
                    response = requests.put(url, data=json.dumps(payload), headers=headers, cookies=cookies)
                else:
                    headers['Content-Type'] = 'application/vnd.com.citrix.netscaler.'+self.get_req_name(path)+'+json'
                    response = requests.post(url, data=json.dumps(payload), headers=headers, cookies=cookies)
            else:
                if method and method.upper() == 'DELETE':
                    response = requests.delete(url, headers=headers, cookies=cookies)
                else:
                    response = requests.get(url, headers=headers, cookies=cookies)

            if response.ok and payload and 'login' in payload:
                self.session = response.cookies['NITRO_AUTH_TOKEN']
                if response.text == '':
                    result = {'headers': response.headers}
                else:
                    result = {'result': response.text}
            else:
                if response.ok:
                    try:
                        result = response.json()
                    except:
                        if response.text == '':
                            result = {'headers': response.headers}
                        else:
                            result = {'result': response.text}
                else:
                    self.errors.append(response.text)
                    print self.errors

            if payload and 'logout' in payload:
                self.end_session()
               
            if self.logging:
                with open('nitro_api.log', 'a') as f:
                    if payload:
                        f.write((method.upper() if method else "POST")+" "+url)
                        f.write('\n')
                        pprint.pprint(payload, f, 2)
                    else:
                        f.write((method.upper() if method else "GET")+" "+url)
                        f.write('\n')
                    f.write('\n')
                    f.write('response:\n')
                    if response.ok:
                        #pprint.pprint(response.headers, f, 2)  # if you want to log the headers too...
                        pprint.pprint(result, f, 2)
                    else:
                        f.write(repr(self.errors))
                        f.write('\n')
                    f.write('\n\n\n')

            return result
        else:
            self.errors.append('missing credentials in the constructor')
            return None
            
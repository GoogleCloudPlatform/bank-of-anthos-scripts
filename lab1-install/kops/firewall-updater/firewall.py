#!/usr/bin/env python

# Copyright 2020 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# docs: https://cloud.google.com/compute/docs/tutorials/python-guide#running_the_sample
# adapted from: https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/compute/api/create_instance.py
# scheduler source: https://stackoverflow.com/questions/474528/what-is-the-best-way-to-repeatedly-execute-a-function-every-x-seconds


"""Updates kops firewall rules in $PROJECT_ID to allow access.
Runs every 10 seconds.
"""

import argparse
import os
import time
import googleapiclient.discovery
import sched, time
import datetime


# firewall rule specs
config = {
    'name': 'https-api-onprem-k8s-local',
    'description': 'Allow Kops cluster access from Cloud Shell and Cloud Build',
    'disabled': False,
    'targetTags': 'onprem-k8s-local-k8s-io-role-master',
    'sourceRanges': ['0.0.0.0/0'],
    'allowed': [
        {
            'IPProtocol': 'tcp',
            'ports': ["443"],
        }
    ],
}


def update_firewall(compute, project_id):
    global config
    # get https firewall rule + update
    print('\n📆  {:%Y-%b-%d %H:%M:%S}'.format(datetime.datetime.now()))
    try:
        fw = compute.firewalls().get(project=project_id, firewall='https-api-onprem-k8s-local').execute()
        print("🆗  Firewall rule exists. Updating...")
        try:
            update_result = compute.firewalls().update(project=project_id, firewall='https-api-onprem-k8s-local', body=config).execute()
            print("✅  Updated rule")
        except Exception:
            print("error when updating rule")
    except Exception:
        print("⭐️  Getting firewall rule got error - creating rule...")
        insert_result = compute.firewalls().insert(project=project_id, body=config).execute()
        print("✅  Created rule")

def main(project_id):
    print('🔥  Firewall updater - Kops cluster 🔥')

    print('☁️   Initializing GCP client from service account')
    # create client from app default credentials - /tmp/serviceaccount.json
    compute = googleapiclient.discovery.build('compute', 'v1')
    print('🔎  Listing all firewall rules in project...')
    all_rules = compute.firewalls().list(project=project_id).execute()
    print('Got %s rules.' % len(all_rules))

    print('Ready. Starting updater.')

    s = sched.scheduler(time.time, time.sleep)
    def do_something(sc):
        update_firewall(compute, project_id)
        s.enter(10, 1, do_something, (sc,))
    s.enter(10, 1, do_something, (s,))
    s.run()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('project_id', help='Your Google Cloud project ID.')
    args = parser.parse_args()
    main(args.project_id)

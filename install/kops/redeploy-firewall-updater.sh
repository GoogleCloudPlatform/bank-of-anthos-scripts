#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script re-installs the Kops firewall updater without running the full install/cleanup.sh script.


# HOW TO RUN THIS SCRIPT:
# cd $HOME/hybrid-sme/bank-of-anthos-scripts/install
# ./kops/redeploy-firewall-updater.sh


export PROJECT_ID=$(gcloud config get-value project)
export WORK_DIR="`pwd`/workdir"
export SERVICE_ACCOUNT_NAME="kops-firewall-updater"
export KEY_PATH="${WORK_DIR}/${SERVICE_ACCOUNT_NAME}-key.json"


echo "🚧 Manually creating fw rule to access the onprem cluster..."

gcloud compute firewall-rules create https-api-onprem-k8s-local \
    --source-ranges="0.0.0.0/0" --target-tags="onprem-k8s-local-k8s-io-role-master" --allow tcp


echo "🧯 Removing the firewall updater namespace in the onprem cluster..."
kubectx onprem;
kubectl delete ns fw;


echo "🧽 Removing the kops-firewall-updater service account..."
gcloud iam service-accounts delete kops-firewall-updater@${PROJECT_ID}.iam.gserviceaccount.com --quiet

gcloud projects remove-iam-policy-binding ${PROJECT_ID} \
--member serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
--role roles/compute.securityAdmin


echo "🗑 Removing the local service account key downloaded to Cloud Shell...."
rm -r ${KEY_PATH}



echo "🌅 Redeploying the firewall updater to your environment..."
./kops/start-firewall-updater.sh


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

export PROJECT_ID=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export SERVICE_ACCOUNT_NAME="kops-firewall-updater"
export KEY_PATH="${WORK_DIR}/${SERVICE_ACCOUNT_NAME}-key.json"

# Create kops-firewall-updater service account
echo "🔥 Starting firewall updater - creating service account"
gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
    --description="${SERVICE_ACCOUNT_NAME}" \
    --display-name="${SERVICE_ACCOUNT_NAME}"

# Grant service account firewall-updater permissions
echo "✅ Granting service account firewall rule permissions"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/compute.securityAdmin

# Create and save service account key
echo "🔑 Downloading service account key..."
gcloud iam service-accounts keys create ${KEY_PATH} \
  --iam-account ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

# Kops cluster runs the firewall updater as a pod - ie. Kops updates its own firewall rule
echo "☸️  Deploying firewall updater in kops cluster"
kubectx onprem;
kubectl create namespace fw
kubectl label namespace fw istio-injection=false --overwrite

kubectl create secret generic -n fw gac --from-file=gcp=${KEY_PATH}
sed 's/MY_PROJECT/'$PROJECT_ID'/g' kops/firewall-updater/deployment.yaml.tpl > kops/firewall-updater/deployment.yaml
kubectl apply -n fw -f kops/firewall-updater/deployment.yaml

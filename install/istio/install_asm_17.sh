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

echo "### "
echo "### Begin installing Anthos Service Mesh 1.7 - ${CONTEXT}"
echo "### "

# Set vars for DIRs
export WORK_DIR=`pwd`/workdir
export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"
export ISTIO_CONFIG_DIR="$BASE_DIR"

#TO DO - Get current Project ID 
export PROJECT_ID=`gcloud config list --format 'value(core.project)' 2>/dev/null`
#TO DO - Get current Project Number 
export ENVIRON_PROJECT_NUMBER=`gcloud projects describe ${PROJECT_ID} | grep projectNumber | awk -F : '{ print $2 }' | sed "s/'//g" | sed "s/ //g"`
export CLUSTER_NAME=gcp
export CLUSTER_LOCATION=us-central1-c
export WORKLOAD_POOL=${PROJECT_ID}.svc.id.goog
export MESH_ID="proj-${ENVIRON_PROJECT_NUMBER}"

#New ASM 1.7 Installer
mkdir asm
cd asm
curl -O https://storage.googleapis.com/csm-artifacts/asm/install_asm
curl -O https://storage.googleapis.com/csm-artifacts/asm/install_asm.sha256
sha256sum -c --ignore-missing install_asm.sha256
chmod +x install_asm
./install_asm \
  --project_id ${PROJECT_ID} \
  --cluster_name ${CONTEXT}	 \
  --cluster_location us-central1-c \
  --mode install \
  --enable_apis \
  --option egressgateways

# Install Istio on ${CONTEXT}
kubectx ${CONTEXT}

# RBAC to provide access to cluster for GKE Connect
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user="$(gcloud config get-value core/account)"

kubectl get pod -n istio-system

#TO DO - Put in check to ensure ASM installed correctly

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

# Variables
export PROJECT_ID=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="`pwd`/workdir"}
echo "workdir is ${WORK_DIR}"
export PATH=$PATH:$WORK_DIR/bin:

export ONPREM_CLUSTER_NAME_BASE=${GCE_CONTEXT:-"onprem"}
export ONPREM_CLUSTER_NAME=$ONPREM_CLUSTER_NAME_BASE.k8s.local
export ONPREM_KUBECONFIG=$WORK_DIR/${ONPREM_CLUSTER_NAME_BASE}.context
echo "kubeconfig location- ${ONPREM_KUBECONFIG}"

export KOPS_STORE=gs://${PROJECT}-kops-$ONPREM_CLUSTER_NAME_BASE

gcloud config set project ${PROJECT_ID}

# unregister cluster from Anthos hub
echo "☸️ Unregistering onprem cluster from Hub..."
gcloud container hub memberships unregister ${ONPREM_CLUSTER_NAME_BASE} \
   --project=${PROJECT_ID} \
   --context=$ONPREM_CLUSTER_NAME \
   --kubeconfig=$ONPREM_KUBECONFIG \

echo "☸️ Deleting onprem Kops cluster..."
kops delete cluster --name $ONPREM_CLUSTER_NAME --state $KOPS_STORE --yes
gsutil -m rm -r $KOPS_STORE
kubectx -d $ONPREM_CLUSTER_NAME_BASE





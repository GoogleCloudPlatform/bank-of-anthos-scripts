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
export PROJECT=$(gcloud config get-value project)
export PROJECT_ID=${PROJECT}
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

#export CLUSTER_NAME="gcp"
#export CLUSTER_ZONE="us-central1-b"
export CLUSTER_NAME=$1
export CLUSTER_ZONE=$2
export CLUSTER_KUBECONFIG=$WORK_DIR/${CLUSTER_NAME}/central.context

export USER="`whoami`@google.com"
export SVC_ACCT_NAME="${CLUSTER_NAME}-connect"
export LOCAL_KEY_PATH="./workdir/${SVC_ACCT_NAME}"

# https://cloud.google.com/anthos/multicluster-management/connect/prerequisites

echo "🔑 Creating GKE Connect service account - ${CLUSTER_NAME} cluster"
gcloud config set project ${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member user:${USER} \
 --role=roles/gkehub.admin \
 --role=roles/iam.serviceAccountAdmin \
 --role=roles/iam.serviceAccountKeyAdmin \
 --role=roles/resourcemanager.projectIamAdmin

gcloud iam service-accounts create ${SVC_ACCT_NAME} --project=${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${SVC_ACCT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/gkehub.connect"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
 --member="serviceAccount:${SVC_ACCT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
 --role="roles/gkehub.connect"

gcloud iam service-accounts keys create ${LOCAL_KEY_PATH} \
  --iam-account=${SVC_ACCT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID}


# https://cloud.google.com/anthos/multicluster-management/connect/registering-a-cluster#register_cluster

echo "⬆️ Registering ${CLUSTER_NAME} to GKE Hub..."
gcloud container hub memberships register ${CLUSTER_NAME} \
   --project=${PROJECT_ID} \
   --gke-cluster="${CLUSTER_ZONE}/${CLUSTER_NAME}" \
   --service-account-key-file=${LOCAL_KEY_PATH}

echo "✅ Done"
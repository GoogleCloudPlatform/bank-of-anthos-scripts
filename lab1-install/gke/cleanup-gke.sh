
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
export WORK_DIR=${WORK_DIR:="`pwd`/workdir"}

export CLUSTER_NAME="gcp"
export CLUSTER_ZONE="us-central1-b"

# unregister cluster from Anthos hub
echo "☸️ Unregistering gcp cluster from Hub..."
gcloud container hub memberships unregister ${CLUSTER_NAME} \
   --project=${PROJECT_ID} \
   --gke-cluster="${CLUSTER_ZONE}/${CLUSTER_NAME}"

# delete GKE cluster
echo "☸️ Deleting gcp cluster..."
gcloud container clusters delete --quiet ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project=${PROJECT_ID}
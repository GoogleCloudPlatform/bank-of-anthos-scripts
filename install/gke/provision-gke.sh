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
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}


export CLUSTER=$1
export ZONE=$2
#export CLUSTER="gcp"
#export ZONE="us-central1-b"
export CLUSTER_KUBECONFIG=$WORK_DIR/${CLUSTER}/central.context

gcloud config set compute/zone ${ZONE}


echo "### "
echo "### Begin Provision GKE"
echo "### "

# GKE cluster with workload identity, needed for ASM
gcloud beta container clusters create $CLUSTER --zone $ZONE \
    --machine-type=n1-standard-4 \
    --num-nodes=4 \
    --enable-stackdriver-kubernetes \
    --subnetwork=default \
    --no-enable-autoupgrade \
    --no-enable-autorepair \

gcloud container clusters get-credentials ${CLUSTER} --zone ${ZONE}

kubectx ${CLUSTER}=gke_${PROJECT}_${ZONE}_${CLUSTER}
kubectx ${CLUSTER}

KUBECONFIG= kubectl config view --minify --flatten --context=$CLUSTER > $CLUSTER_KUBECONFIG







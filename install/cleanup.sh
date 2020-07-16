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
removeServiceAccount() {
  echo "Removing Service Account"
  KEY=$(gcloud iam service-accounts keys list --iam-account $1 --managed-by user | grep -v KEY | xargs | cut -d " " -f 1)
  if [ ! -z ${KEY} ]
  then
    gcloud iam service-accounts keys delete ${KEY} --iam-account $1 -q || true
  fi

  gcloud iam service-accounts delete $1 -q || true
  roles=$(gcloud projects get-iam-policy $PROJECT --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:$1" | grep -v ROLE)
  #declare -a roles=(${SVC_ACC_ROLES})
  for role in "${roles[@]}"
  do
    echo "Removing role: ${role} to service account $1"
    gcloud projects remove-iam-policy-binding ${2} --member "serviceAccount:$1" --role "${role}" --quiet > /dev/null || true
  done
}

if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then
    export PROJECT_ID=$(gcloud config get-value project)
    export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

    echo "🧹 Cleaning up Anthos environment in project: ${PROJECT_ID}"
    source ./env


    echo "☁️ Unregistering clusters from Anthos..."
    gcloud container hub memberships delete gcp --quiet
    gcloud container hub memberships delete onprem --quiet


    echo "☁️ Removing Kubernetes clusters from your project. This may take a few minutes ."
    ./kops/cleanup-remote-gce.sh &> ${WORK_DIR}/cleanup-remote.log &
    ./gke/cleanup-gke.sh &> ${WORK_DIR}/cleanup-gke.log &
    wait

    echo "🔥 Cleaning up forwarding and firewall rules."
    gcloud compute forwarding-rules delete $(gcloud compute forwarding-rules list --format="value(name)") --region us-central1 --quiet
    gcloud compute target-pools delete $(gcloud compute target-pools list --format="value(name)") --region us-central1 --quiet
    NODE_RULE="`gcloud compute firewall-rules list --format="table(name,targetTags.list():label=TARGET_TAGS)" | grep onprem-k8s-local-k8s-io-role-node | awk '{print $1}'`"
    gcloud compute firewall-rules delete ${NODE_RULE} --quiet

    echo "🐙 Deleting CSR repos."
    gcloud source repos delete config-repo --quiet
    gcloud source repos delete app-config-repo --quiet
    gcloud source repos delete source-repo --quiet

    echo "☸️ Deleting onprem context from Secret Manager"
    gcloud secrets delete onprem-context --quiet

    echo "🔄 Deleting Cloud Build trigger for app config repo"
    gcloud beta builds triggers delete trigger --quiet


    echo "🔑 Deleting Firewall updater service account..."
    removeServiceAccount kops-firewall-updater@${PROJECT_ID}.iam.gserviceaccount.com ${PROJECT_ID}

    echo "🔑 Deleting GCP cluster Hub service account..."
    removeServiceAccount gcp-connect@${PROJECT_ID}.iam.gserviceaccount.com ${PROJECT_ID}

    echo "🔑 Deleting onprem cluster Hub service account..."
    removeServiceAccount anthos-connect@${PROJECT_ID}.iam.gserviceaccount.com ${PROJECT_ID}

    echo "🗑 Finishing up."
    rm -rf $HOME/.kube/config \
           $HOME/hybrid-sme/app-config-repo \
           $HOME/hybrid-sme/config-repo \
           $HOME/hybrid-sme/source-repo \
           $HOME/hybrid-sme/cloud-builders-community \
           $HOME/.ssh/id_rsa.nomos.*

    rm -f $HOME/.customize_environment
    rm -rf $WORK_DIR

    echo "✅ Cleanup complete. You can continue using ${PROJECT_ID}."

else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

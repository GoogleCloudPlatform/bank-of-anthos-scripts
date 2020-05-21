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

if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then
    echo "🧹 Cleaning up Anthos environment in project: ${PROJECT_ID}"
    source ./env

    export PROJECT=$(gcloud config get-value project)
    export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

    echo "☁️ Removing Kubernetes clusters from your project... This may take a few minutes ..."
    ./kops/cleanup-remote-gce.sh &> ${WORK_DIR}/cleanup-remote.log &
    ./gke/cleanup-gke.sh &> ${WORK_DIR}/cleanup-gke.log &
    wait

    echo "📂 Removing your workdir..."
    rm -rf $WORK_DIR

    echo "🔥 Cleaning up forwarding and firewall rules..."
    gcloud compute forwarding-rules delete $(gcloud compute forwarding-rules list --format="value(name)") --region us-central1 --quiet
    gcloud compute target-pools delete $(gcloud compute target-pools list --format="value(name)") --region us-central1 --quiet
    gcloud compute firewall-rules delete \
	$(gcloud compute firewall-rules list --format="table(name,targetTags.list():label=TARGET_TAGS)" | \
	grep remote-k8s-local-k8s-io-role-node | \
	awk '{print $1}'\
	) --quiet

    echo "🐙 Deleting CSR repos..."
    gcloud source repos delete config-repo --quiet
    gcloud source repos delete app-repo --quiet

    # Delete remaining files and folders
    echo "🗑 Finishing up..."
    rm -rf $HOME/.kube/config \
           $HOME/config-repo \
           $HOME/app-repo \
           $HOME/gopath \
           $HOME/.ssh/id_rsa.nomos.*

    rm -f $HOME/.customize_environment

    echo "✅ Cleanup complete. You can continue using ${PROJECT_ID}."

else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

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

# Variables & Functions
enableAPIs() {
  if [ "$#" -eq 0 ]; then
    echo "Usage: $0 APIs" >&2
    echo "e.g. $0 iam compute" >&2
    exit 1
  fi

  echo "Required apis for this project are: $@"
  declare -a REQ_APIS=(${@})

  local ENABLED_APIS=$(gcloud services list --enabled | grep -v NAME | sort | cut -d " " -f1)
  #echo "Current APIs enabled are: ${ENABLED_APIS}"

  for api in "${REQ_APIS[@]}"
  do
    printf "\t 👀 Checking to see if ${api} api is enabled on this project\n"
    local API_EXISTS=$(echo ${ENABLED_APIS} | grep ${api}.googleapis.com | wc -l)
    if [ ${API_EXISTS} -eq 0 ]
    then
      echo "***💡 Enabling ${api} API"
      gcloud services enable "${api}.googleapis.com"
    fi
  done
}

if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then
    echo "********* Welcome to the Hybrid SME Academy Labs ***************"
    echo "⚡️ Starting Anthos environment install."
    export PROJECT=$(gcloud config get-value project)
    export BASE_DIR=${BASE_DIR:="${PWD}"}
    export WORK_DIR=${WORK_DIR:="${BASE_DIR}/workdir"}

    echo "WORK_DIR set to $WORK_DIR"
    gcloud config set project $PROJECT

    #Looking for SME_BASE_INST run evidence
    echo "👀 Looking if SME_BASE_INST has been updated."
    echo "SME_BASE_INST:" $SME_BASE_INST
    if [ -n "$SME_BASE_INST" ]; then
        echo "✅ env SME_BASE_INST environment value is already present - skipping"
    else
        echo "🖝 env SME_BASE_INST environment value is not present - continuing"
        ./common/install-tools.sh
    fi

    #Additional if statements to avoid repeated additions of lines to ~/.bashrc
    echo "🚪 Configuring Cloud Shell to re-init environment if disconnected."
    BASHRC_UPDATED="$(grep /bank-of-anthos-scripts/install/env ~/.bashrc)"
    if [ -n "$BASHRC_UPDATED" ]; then
        echo "✅ env init string is already present - skipping"
    else
        echo "🖝 env init string is not present - adding"
        echo "source $ROOT/bank-of-anthos-scripts/install/env" >> ~/.bashrc 
    fi
    BASHRC_UPDATED="$(grep /bank-of-anthos-scripts/install/common ~/.bashrc)"
    if [ -n "$BASHRC_UPDATED" ]; then
        echo "✅ install-tools init string is already present - skipping"
    else
        echo "🖝 install-tools init string is not present - adding"
        echo "source $ROOT/bank-of-anthos-scripts/install/common/install-tools.sh" >> ~/.bashrc 
    fi

    echo "🔆 Enabling GCP APIs. This may take up to 5 minutes."
    APIS="container compute stackdriver meshca meshtelemetry meshconfig iamcredentials anthos cloudresourcemanager gkeconnect gkehub serviceusage sourcerepo cloudbuild secretmanager"
    enableAPIs $APIS

    echo "☸️ Creating 2 Kubernetes clusters in parallel."
    echo -e "\nMultiple tasks are running asynchronously to setup your environment.  It may appear frozen, but you can check the logs in $WORK_DIR for additional details in another terminal window."
    ./gke/provision-gke.sh &> ${WORK_DIR}/provision-gke.log &
    ./kops/provision-remote-gce.sh &> ${WORK_DIR}/provision-remote.log &
    wait

    # generate kops kubecfg
    echo "🎢 Finishing Kops setup, creating kubeconfig."
    ./common/connect-kops-remote.sh

    # configure Kops firewall rules + continually allow Kops kubectl access
    echo "🔥🧱🗘 Configuring Firewall and continual Kops Kubectl access."
    ./kops/start-firewall-updater.sh

    # install service mesh: Istio, replicated control plane multicluster
    echo "🕸 Installing service mesh on both clusters."
    CONTEXT="gcp" ./istio/install_istio.sh
    CONTEXT="onprem" ./istio/install_istio.sh

    # configure DNS stubdomains for cross-cluster service name resolution
    echo "🌏 Connecting the 2 Istio control planes into one mesh."
    ./istio/coredns.sh

    # ACM pre-install
    echo "🐙 Installing Anthos Config Management on both clusters."
    kubectx gcp && ./acm/install-config-operator.sh
    kubectx onprem && ./acm/install-config-operator.sh

    # Cloud Build setup
    echo "🔄 Setting up Cloud Build for later."
    ./cloudbuild/setup.sh

    # install GKE connect on both clusters / print onprem login token
    echo "⬆️ Installing GKE Connect on both clusters."
    ./gke/connect-hub.sh
    ./kops/connect-hub.sh

    echo "✅ Bootstrap script complete."
else
    echo "This has only been tested in GCP Cloud Shell.  Only Linux (debian) is supported".
fi

# aliases for kubectl
kubectlg(){
  kubectx gcp;
  kubectl "${@}"
}

kubectlo(){
  kubectx onprem;
  kubectl "${@}"
}
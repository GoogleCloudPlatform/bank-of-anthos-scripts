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
export EMAIL=$(gcloud config get-value account)
export ROOT=$HOME/hybrid-sme

echo "👋 Welcome back to the Hybrid SME Academy labs."

git config --global user.email $EMAIL
git config --global user.name $EMAIL

# creating keys if they do not not exist
mkdir ~/.ssh
if [ $(ls -1 ~/.ssh | grep id_rsa.sme | wc -l) != 2 ]; then ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa.sme -q -N ""; fi


echo "🏔 Lab 1 - Begin Fast Track"
echo "⏰ This script will bootstrap an Anthos environment for you."

export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export ROOT=$HOME/hybrid-sme

# Check if project setup is needed
if [ "$1" == "setup" ]
then
  echo "☁️ Project setup"
  mkdir -p $ROOT
  # GCP_DEVREL_UNTRUSTED_FOLDER_ID="1053275019153"
  EXPERIMENTAL_ANTHOS_ID="130886061063"
  DATE=`date +"%m%d%y-%H%M"`
  PROJECT_ID="${USER}-sme-${DATE}"
  gcloud projects create $PROJECT_ID --folder=${EXPERIMENTAL_ANTHOS_ID}
  gcloud config set project $PROJECT_ID
  gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ID
fi

cd $ROOT; cd bank-of-anthos-scripts/install/
source ./env
source ./common/install-tools.sh

#Staring bootstrap script
echo "🚀 Running bootstrap script - this will take about 10 minutes."

if [[ $OSTYPE == "linux-gnu" && $CLOUD_SHELL == true ]]; then
    echo "********* Welcome to the Hybrid SME Academy Labs ***************"
    echo "⚡️ Starting Anthos environment install."
    export PROJECT=$(gcloud config get-value project)
    export BASE_DIR=${BASE_DIR:="${PWD}"}
    export WORK_DIR=${WORK_DIR:="${BASE_DIR}/workdir"}

    echo "WORK_DIR set to $WORK_DIR"
    gcloud config set project $PROJECT

    echo "🛠 Installing client tools."
    ./common/install-tools.sh

    echo "🚪 Configuring Cloud Shell to re-init environment if disconnected."
    if grep -Fxq "source $ROOT/bank-of-anthos-scripts/install/env" ~/.bashrc
       then
	 echo ".bashrc additions found, already configured."
       else
         echo "source $ROOT/bank-of-anthos-scripts/install/env" >> ~/.bashrc
         echo "source $ROOT/bank-of-anthos-scripts/install/common/install-tools.sh" >> ~/.bashrc
    fi

    echo "🔆 Enabling GCP APIs. This may take up to 5 minutes."
    gcloud services enable \
    container.googleapis.com \
    compute.googleapis.com \
    stackdriver.googleapis.com \
    meshca.googleapis.com \
    meshtelemetry.googleapis.com \
    meshconfig.googleapis.com \
    iamcredentials.googleapis.com \
    anthos.googleapis.com \
    cloudresourcemanager.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    serviceusage.googleapis.com \
    sourcerepo.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com

    echo "☸️ Creating 2 Kubernetes clusters in parallel."
    echo -e "\nMultiple tasks are running asynchronously to setup your environment.  It may appear frozen, but you can check the logs in $WORK_DIR for additional details in another terminal window."
    ./gke/provision-gke.sh &> ${WORK_DIR}/provision-gke.log &
    ./kops/provision-remote-gce.sh &> ${WORK_DIR}/provision-remote.log &
    wait

    # generate kops kubecfg
    echo "🎢 Finishing Kops setup, creating kubeconfig."
    ./common/connect-kops-remote.sh

    # configure Kops firewall rules + continually allow Kops kubectl access
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

#End of bootstrap script

echo "🐙 Bootstrap done! Set up ACM config repo..."


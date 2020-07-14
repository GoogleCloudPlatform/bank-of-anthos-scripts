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

# This fast track script is intended only for Lab 1. It creates a new GCP project. If you want to spin up the Lab 1-2 environment on your existing project use install/spin-up.sh.

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

echo "🚀 Running bootstrap script - this will take about 10 minutes."
./bootstrap.sh

read -n 1 -p "Login to your onprem cluster in the Cloud Console with KSA token above. Hit any key to continue."

echo "🐙 Bootstrap done! Set up ACM config repo..."
export REPO_URL=https://source.developers.google.com/p/${PROJECT_ID}/r/config-repo
git config credential.helper gcloud.sh
gcloud source repos create config-repo
cd $ROOT
gcloud source repos clone config-repo
cd config-repo

cp -r $ROOT/bank-of-anthos-scripts/install/acm/config-repo-source/* .

git add .
git commit -m "Initialize config-repo"
git push -u origin master


echo "🔑 Granting ACM config-repo access..."
# do *not* run ssh-keygen again. this key persists in the user's environment after cleanup.

kubectx gcp
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.sme

kubectx onprem
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.sme

echo "⬇️ Creating ConfigManagement CRD in both clusters..."
export ONPREM=onprem
export GCP=gcp
SSH_REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT_ID}/r/config-repo

kubectx $ONPREM
cat $BASE_DIR/acm/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$SSH_REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$ONPREM"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -n config-management-system -f -

kubectx $GCP
cat $BASE_DIR/acm/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$SSH_REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$GCP"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -n config-management-system -f -


echo "✅ Lab 1 fast track complete!"

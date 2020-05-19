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


echo "🏔 Lab 1 - Begin Fast Track"
echo "⏰ This script will bootstrap an Anthos environment for you."

export GCLOUD_ACCOUNT=$(gcloud config get-value account)

echo "☁️ Project setup"
GCP_DEVREL_UNTRUSTED_FOLDER_ID="1053275019153"
DATE=`date +"%m%d%y-%H%M"`
PROJECT_ID="${USER}-sme-${DATE}"
gcloud projects create $PROJECT_ID --folder=${GCP_DEVREL_UNTRUSTED_FOLDER_ID}
gcloud config set project $PROJECT_ID
gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ID
cd $HOME; cd bank-of-anthos-scripts/lab1-install/
source ./env

echo "🚀 Running bootstrap script - this will take about 10 minutes."
./bootstrap.sh


echo "🐙 Bootstrap done! Set up ACM config repo..."
export REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo
git config credential.helper gcloud.sh
gcloud source repos create config-repo
cd $HOME
gcloud source repos clone config-repo
cd config-repo

cp -r $HOME/bank-of-anthos-scripts/lab1-install/acm/config-repo-source/* .

git add .
git commit -m "Initialize config-repo"
git push -u origin master


echo "🔑 Granting ACM config-repo access..."
ssh-keygen -t rsa -b 4096 \
-C "$GCLOUD_ACCOUNT" \
-N '' \
-f $HOME/.ssh/id_rsa.nomos

kubectx gcp
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos

kubectx onprem
kubectl create secret generic git-creds \
--namespace=config-management-system \
--from-file=ssh=$HOME/.ssh/id_rsa.nomos

echo "⬇️ Creating ConfigManagement CRD in both clusters..."
export ONPREM=onprem
export GCP=gcp
REPO_URL=ssh://${GCLOUD_ACCOUNT}@source.developers.google.com:2022/p/${PROJECT}/r/config-repo

kubectx $ONPREM
cat $BASE_DIR/acm/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$ONPREM"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f -

kubectx $GCP
cat $BASE_DIR/acm/config_sync.yaml | \
  sed 's|<REPO_URL>|'"$REPO_URL"'|g' | \
  sed 's|<CLUSTER_NAME>|'"$GCP"'|g' | \
  sed 's|none|ssh|g' | \
  kubectl apply -f -


echo "✅ Lab 1 fast track complete!"
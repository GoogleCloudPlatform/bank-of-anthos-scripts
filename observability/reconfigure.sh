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

export REPO_NAME="app-config-repo"
export PROJECT_REPO_URL=https://source.developers.google.com/p/${PROJECT_ID}/r/${REPO_NAME}
export ROOT=$HOME/hybrid-sme
IP_1=$(kubectl --context=gcp get -n istio-system service istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
IP_2=$(kubectl --context=onprem get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
IP_3=$(kubectl --context=gcp get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# create CSR repo for Lab 3
echo "🚀 Creating new app-repo for observability lab"
git config --global user.email "$EMAIL"
git config --global user.name "$USER"

gcloud source repos create ${REPO_NAME}

echo "🏠 Setting up local repo"
cd $ROOT
gcloud source repos clone ${REPO_NAME}

echo "🏗 Copying cloudbuild.yaml into app repo"
cp ${ROOT}/bank-of-anthos-scripts/deploy-app/cloudbuild.yaml ${ROOT}/${REPO_NAME}

echo "🔄 Creating a Cloud Build trigger for app repo"
gcloud beta builds triggers create cloud-source-repositories \
--repo=${REPO_NAME} \
--branch-pattern="master" \
--build-config="cloudbuild.yaml"

echo "⛵️ Generating Istio service entries for gcp cluster"
mkdir -p ${ROOT}/${REPO_NAME}/gcp
mkdir -p ${ROOT}/${REPO_NAME}/onprem
sed 's/IP_1/'$IP_1'/g; s/IP_2/'$IP_2'/g; s/IP_3/'$IP_3'/g' $ROOT/bank-of-anthos-scripts/observability/gcp/service-entries.yaml.tpl > $ROOT/bank-of-anthos-scripts/observability/gcp/service-entries.yaml

echo "🏦 Copying Bank of Anthos manifests into app repo"
cp $ROOT/bank-of-anthos-scripts/observability/gcp/*.yaml ${ROOT}/${REPO_NAME}/gcp
cp $ROOT/bank-of-anthos-scripts/deploy-app/onprem/* ${ROOT}/${REPO_NAME}/onprem

echo "⏫ Pushing to $REPO_NAME master"
cd $ROOT/$REPO_NAME
git add .
git commit -m "cloudbuild.yaml, Bank of Anthos init"
git push -u origin master


echo "⭐️ Navigate to this URL to view the status of Cloud Build:"
echo "http://console.cloud.google.com/cloud-build/dashboard?project=${PROJECT_ID}"
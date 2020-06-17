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
export REPO_NAME="app-config-repo"
export PROJECT_REPO_URL=https://source.developers.google.com/p/${PROJECT_ID}/r/$REPO_NAME
export ROOT=$HOME/hybrid-sme

# create CSR repo
echo "*************** Welcome to Lab 2 - Cloud Build + CI/CD *********************** "
echo "🚀 Creating $REPO_NAME"
git config --global user.email "$EMAIL"
git config --global user.name "$USER"

gcloud source repos create $REPO_NAME

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

GWIP_ONPREM=$(kubectl --context=onprem get -n istio-system service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
sed 's/GWIP_ONPREM/'$GWIP_ONPREM'/g' $ROOT/bank-of-anthos-scripts/deploy-app/gcp/service-entries.yaml.tpl > ${ROOT}/${REPO_NAME}/gcp/service-entries.yaml

echo "🏦 Copying Bank of Anthos manifests into app repo"
cp $ROOT/bank-of-anthos-scripts/deploy-app/gcp/* ${ROOT}/${REPO_NAME}/gcp
cp $ROOT/bank-of-anthos-scripts/deploy-app/onprem/* ${ROOT}/${REPO_NAME}/onprem


echo "⏫ Pushing to $REPO_NAME master"
cd $ROOT/$REPO_NAME
git add .
git commit -m "cloudbuild.yaml, Bank of Anthos init"
git push -u origin master


echo "⭐️ Navigate to this URL to view the status of Cloud Build:"
echo "http://console.cloud.google.com/cloud-build/dashboard?project=${PROJECT_ID}"
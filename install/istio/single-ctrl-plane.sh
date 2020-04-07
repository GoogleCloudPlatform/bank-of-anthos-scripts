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

# SOURCE - https://cloud.google.com/service-mesh/docs/gke-install-new-cluster

# Set vars
export CTRL_CTX="gcp"
export CTRL_CLUSTER_NAME="gcp"
export CTRL_CLUSTER_ZONE="us-central1-b"
export REMOTE_CTX="onprem"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export ISTIO_VERSION="1.4.7"
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}

cd $WORK_DIR

echo "### "
echo "### Begin install Istio control plane - ${CTRL_CTX}"
echo "### "

echo "🔥 Creating firewall rule across cluster pods..."

# Pod CIDRs  - allow "from"
GCP_POD_CIDR=$(gcloud container clusters describe ${CTRL_CLUSTER_NAME} --zone ${CTRL_CLUSTER_ZONE} --format=json | jq -r '.clusterIpv4Cidr')

kubectx $REMOTE_CTX
CIDR=`kubectl cluster-info dump | grep -m 1 cluster-cidr`
CIDR=`cut -d "=" -f2 <<< "$CIDR"`
CIDR=`echo $CIDR | tr -d \"`
ONPREM_POD_CIDR=`echo $CIDR | tr -d ','`

ALL_CLUSTER_CIDRS=$GCP_POD_CIDR,$ONPREM_POD_CIDR

# Instance VM Network tags - allow "to"
ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --format=json | jq -r '.[].tags.items[0]' | uniq | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')

# allow direct traffic between pods in both gcp and onprem clusters
gcloud compute firewall-rules create istio-multicluster-pods \
    --allow=tcp,udp,icmp,esp,ah,sctp \
    --direction=INGRESS \
    --priority=900 \
    --source-ranges="${ALL_CLUSTER_CIDRS}" \
    --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet

echo "🔥 Updating onprem firewall rule to support discovery from GCP Istio..."
# update onprem firewall rule to allow traffic from all sources
# (allows gcp pilot discovery--> onprem kube apiserver)
gcloud compute firewall-rules update cidr-to-master-onprem-k8s-local --source-ranges="0.0.0.0/0"

echo "🌩 Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
cp istio-$ISTIO_VERSION/bin/istioctl $WORK_DIR/bin/.
mv istio-$ISTIO_VERSION $WORK_DIR/
cd $WORK_DIR/istio-$ISTIO_VERSION
export PATH=$PWD/bin:$PATH

echo "⛵️ Installing the Istio control plane on ${CTRL_CTX}..."
kubectx $CTRL_CTX
istioctl manifest apply \
--set values.grafana.enabled=true \
--set values.kiali.enabled=true \
--set values.kiali.enabled=true --set values.kiali.createDemoSecret=true \
--set values.global.proxy.accessLogFile="/dev/stdout"

echo "⏱ Wait for Istio control plane to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system

echo "📊 Install the Mixer Stackdriver Adapter"
git clone https://github.com/istio/installer && cd installer
helm template istio-telemetry/mixer-telemetry --execute=templates/stackdriver.yaml -f global.yaml --set mixer.adapters.stackdriver.enabled=true --namespace istio-system | kubectl apply -f -


echo "### "
echo "### Begin installing the Istio remote - ${REMOTE_CTX}"
echo "### "

# still on the ctrl plane kubectx
export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')


kubectx $REMOTE_CTX

echo "🏝 Installing Istio remote on ${REMOTE_CTX} cluster..."
istioctl manifest apply \
--set profile=remote \
--set values.global.controlPlaneSecurityEnabled=false \
--set values.global.createRemoteSvcEndpoints=true \
--set values.global.remotePilotCreateSvcEndpoint=true \
--set values.global.remotePilotAddress=${PILOT_POD_IP} \
--set values.global.remoteTelemetryAddress=${TELEMETRY_POD_IP} \
--set gateways.enabled=false \
--set autoInjection.enabled=true \
--set values.global.proxy.accessLogFile="/dev/stdout"


echo "⏱ Wait for Istio remote to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment --all -n istio-system


echo "### "
echo "### Set up cross cluster discovery"
echo "### "

# source: https://archive.istio.io/v1.4/docs/setup/install/multicluster/shared-vpn/#install-the-istio-remote
# give the GCP cluster access to Onprem's K8s services

# do all this on remote cluster
echo "🔑 Getting remote cluster credentials..."
kubectx $REMOTE_CTX
mkdir -p "$WORK_DIR/istio-secret"
CLUSTER_NAME=${REMOTE_CTX}
export KUBECFG_FILE="${WORK_DIR}/istio-secret/${CLUSTER_NAME}"

SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
NAMESPACE=istio-system
SERVICE_ACCOUNT=istio-reader-service-account
SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)

# generate an istio-reader kubecfg file
cat <<EOF > ${KUBECFG_FILE}
apiVersion: v1
clusters:
   - cluster:
       certificate-authority-data: ${CA_DATA}
       server: ${SERVER}
     name: ${CLUSTER_NAME}
contexts:
   - context:
       cluster: ${CLUSTER_NAME}
       user: ${CLUSTER_NAME}
     name: ${CLUSTER_NAME}
current-context: ${CLUSTER_NAME}
kind: Config
preferences: {}
users:
   - name: ${CLUSTER_NAME}
     user:
       token: ${TOKEN}
EOF

# switch to ctrl plane cluster / add that file as a secret called "onprem"
echo "🔒 Adding remote cluster info to gcp cluster..."
kubectx $CTRL_CTX
kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}

echo "✅ Istio install complete."
cd ..
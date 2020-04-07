#!/usr/bin/env bash

# Copyright 2019 Google LLC
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

echo "### "
echo "### Begin install istio control plane - ${CONTEXT}"
echo "### "


# Set vars for DIRs
export ISTIO_VERSION=1.4.7
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"
export ISTIO_CONFIG_DIR="$BASE_DIR"

# Install Istio on ${CONTEXT}
kubectx ${CONTEXT}

# Create istio-system namespace
kubectl create namespace istio-system
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

# Create a secret with the sample certs for multicluster deployment
kubectl --context ${CONTEXT} create secret generic cacerts -n istio-system \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/ca-key.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/root-cert.pem \
--from-file=${WORK_DIR}/istio-${ISTIO_VERSION}/samples/certs/cert-chain.pem

# install istio CRDs
helm template ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -

# wait until all CRDs are installed
until [ $(kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l) = 23 ]; do echo "Waiting for Istio CRDs to install..." && sleep 3; done

# Confirm Istio CRDs ae installed
echo "Istio CRDs installed" && kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

# Install Istio
helm template ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio --name istio --namespace istio-system \
--values ${WORK_DIR}/istio-${ISTIO_VERSION}/install/kubernetes/helm/istio/example-values/values-istio-multicluster-gateways.yaml \
--set global.proxy.accessLogFile="/dev/stdout" \
--set prometheus.enabled=true \
--set tracing.enabled=true \
--set kiali.enabled=true --set kiali.createDemoSecret=true \
--set "kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
--set "kiali.dashboard.grafanaURL=http://grafana:3000" \
--set grafana.enabled=true >> ${WORK_DIR}/istio-${ISTIO_VERSION}/istio-${CONTEXT}.yaml

kubectl apply -f ${WORK_DIR}/istio-${ISTIO_VERSION}/istio-${CONTEXT}.yaml

# install the Stackdriver adapter
git clone https://github.com/istio/installer && cd installer
helm template istio-telemetry/mixer-telemetry --execute=templates/stackdriver.yaml -f global.yaml --set mixer.adapters.stackdriver.enabled=true --namespace istio-system | kubectl apply -f -
cd ..
rm -rf installer/
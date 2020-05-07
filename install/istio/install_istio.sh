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
#!/bin/bash

# installs standard single-cluster Istio on GKE + the Istio Stackdriver adapter

# Download Istio

echo "### "
echo "### Begin install istio control plane - ${CONTEXT}"
echo "### "


# Set vars for DIRs
ISTIO_VERSION="${ISTIO_VERSION:-1.5.2}"
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export ISTIO_DIR=$WORK_DIR/istio-$ISTIO_VERSION
export BASE_DIR=${BASE_DIR:="${PWD}/.."}
echo "BASE_DIR set to $BASE_DIR"
export ISTIO_CONFIG_DIR="$BASE_DIR"

# Install Istio on ${CONTEXT}
kubectx ${CONTEXT}

echo "Downloading Istio ${ISTIO_VERSION}..."
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# Prepare for install
kubectl create namespace istio-system

cd ./istio-${ISTIO_VERSION}/
kubectl create secret generic cacerts -n istio-system \
    --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem \
    --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem
cd ../

kubectl label namespace default istio-injection=enabled
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)


# install using operator config - https://istio.io/docs/setup/install/istioctl/#customizing-the-configuration
INSTALL_PROFILE="install-dual-ctrl.yaml"
./istio-${ISTIO_VERSION}/bin/istioctl manifest apply -f ${INSTALL_PROFILE}
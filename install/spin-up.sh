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

cd $ROOT/bank-of-anthos-scripts/install/
./fasttrack.sh

cat $HOME/.ssh/id_rsa.nomos.pub
read -n 1 -p "Please register your SSH key before continuing. Hit any key to continue."

# Wait for boa namespace to be synced from ACM
echo "💤 Sleeping 3 minutes to wait for ACM to be ready"
sleep 3m

# Lab 2 fast track
cd $ROOT/bank-of-anthos-scripts/deploy-app/
./fasttrack.sh
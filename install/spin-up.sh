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

# Lab 1 fast track, minus project creation and billing
./fasttrack.sh


# Wait for boa namespace to be synced from ACM
echo "💤 Sleeping 3 minutes to wait for ACM to be ready"
sleep 3m

# Lab 2 fast track
../deploy-app/fasttrack.sh
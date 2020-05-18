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
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)")
export SECRET_NAME="onprem-context"
export SECRET_FILE="${WORK_DIR}/onprem.context"

echo "☸️ Write the onprem kubeconfig to Secret Manager"
gcloud secrets create ${SECRET_NAME} --replication-policy=automatic \
    --data-file=${SECRET_FILE}


# https://cloud.google.com/iam/docs/understanding-roles#predefined_roles
echo "✅ Give Cloud Build worker access to GKE, Secret Manager"

export CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${CB_SA} \
  --role roles/secretmanager.secretAccessor

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${CB_SA} \
  --role roles/container.developer

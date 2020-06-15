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

export PROJECT=$(gcloud config get-value project)
export EMAIL=$(gcloud config get-value account)
git config --global user.email "$EMAIL"
git config --global user.name "$USER"

export REPO_URL=${REPO_URL:-"https://github.com/cgrant/hipster"}
export REPO_BRANCH=${REPO_BRANCH:-"master"}

cd $HOME
export GCLOUD_ACCOUNT=$(gcloud config get-value account)
export PROJECT_REPO_URL=https://source.developers.google.com/p/${PROJECT}/r/config-repo


if [[ ${REPO_BRANCH} != "master" ]]; then
    git clone ${REPO_URL} -b ${REPO_BRANCH} config-repo
else
    git clone ${REPO_URL} config-repo
fi

cd config-repo
git remote remove origin
git config credential.helper gcloud.sh
git remote add origin $PROJECT_REPO_URL

gcloud source repos create config-repo
if [[ ${REPO_BRANCH} != "master" ]]; then
    git push -u origin ${REPO_BRANCH}
else
    git push -u origin master
fi

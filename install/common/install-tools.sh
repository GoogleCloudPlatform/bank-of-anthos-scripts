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

echo "### "
echo "📝 Continuing set up and validating Environment Variables"
echo "### "

echo "🔍 Checking if PROJECT ID variable is correctly populated..." 
PROJECT_ID_CHECK=$(grep '^export PROJECT_ID=""' "$ROOT/bank-of-anthos-scripts/install/common/install-tools.sh")
#echo "PROJECT_ID_CHECK is:" $PROJECT_ID_CHECK
if [[ ! -z "$PROJECT_ID_CHECK" ]]; then
    echo "❗🚨 PROJECT ID variable is blank in '$ROOT/bank-of-anthos-scripts/install/common/install-tools.sh' - please edit and update!"
    echo "❗🚨 $ROOT/bank-of-anthos-scripts/install/common/install-tools.sh will now exit!"
    CONTINUE="NO"
    echo "CONTINUE=" $CONTINUE
else
echo "✅ PROJECT ID variable has been updated..."
    CONTINUE="YES"
    echo "CONTINUE=" $CONTINUE
fi 

if [ $CONTINUE == "YES" ]; then

# Variables
#export PROJECT_ID=""  #No longer needed - script testing complete
export PROJECT_ID="carhope-sme-070720-1537"
echo "📜 Setting gcloud config project property!"
gcloud config set project "$PROJECT_ID"
export PROJECT=$(gcloud config get-value project)
export WORK_DIR=${WORK_DIR:="${PWD}/workdir"}
export EMAIL=$(gcloud config get-value account)

## Install Tools
mkdir -p $WORK_DIR/bin

echo "### "
echo "⚡️ Starting Anthos Tools install."
echo "🔍 Checking if Anthos Tools install history exists."
echo "### "

INSTALL_LOG=$WORK_DIR/install.log
if [ -f "$INSTALL_LOG" ]; then
    echo "🏁 Install Log exists, tool install process will be skipped."
    LOGLINE=$(head -n 1 $INSTALL_LOG)
    echo "👀 Record from Install Log is:'$LOGLINE'"
    INSTALL_SKIP="YES"
   else
    echo "$INSTALL_LOG does not exist, tool install will proceed."
    INSTALL_SKIP="NO"
fi

if [ $INSTALL_SKIP == "NO" ]; then

## Install kubectx
echo "☸️ Installing Kubectx"
curl -sLO https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
chmod +x kubectx
mv kubectx $WORK_DIR/bin

# Install Kops
echo "☸️ Installing Kops"
curl -sLO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 $WORK_DIR/bin/kops

 # Install nomos
echo "🛠 Installing nomos"
gsutil cp gs://config-management-release/released/latest/linux_amd64/nomos nomos
chmod +x nomos
mv nomos $WORK_DIR/bin

# Docker pull read-yaml command for ACM
echo "🛠 Pulling latest read-yaml"
docker pull gcr.io/config-management-release/read-yaml:latest

# Install tree
echo "🛠 Installing tree"
sudo apt-get install tree

echo "🗒 Updating Tool Install Log."
touch $WORK_DIR/install.log
NOW=$(date +'%d-%b-%Y')
echo "Anthos Tools install completed on:"$NOW  > $WORK_DIR/install.log
echo "✅ Anthos Tools install complete."

else
echo "🚪 Clean Exit!"
fi

else
echo "🚪 Clean Exit!"
fi
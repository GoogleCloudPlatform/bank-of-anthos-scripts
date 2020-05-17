# Cloud Build - Kops + GKE


### Kubectl docker image - Raw docker

export KCFG="/Users/mokeefe/go/src/github.com/askmeegs/bank-of-anthos-scripts/lab1-install/kops/workdir/onprem.context"

docker run --rm --name kubectl -v ${KCFG}:/.kube/config bitnami/kubectl:latest apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/master/release/kubernetes-manifests.yaml


### Running cloud build with substitutions


PROJECT_ID
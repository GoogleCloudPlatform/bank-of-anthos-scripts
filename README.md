# Bank of Anthos - Scripts - Lab 3

This repository contains sample scripts and YAML files for [Anthos](https://cloud.google.com/anthos) demos, based on the [Bank of Anthos](https://github.com/GoogleCloudPlatform/bank-of-anthos) sample application.

git clone -b sme-lab3 remote-repo-url

The `install/` directory contains bootstrap scripts for a 2-cluster Anthos environment, including:
- 1 GKE cluster on GCP
- 1 Kops on GCE cluster
- Istio (Dual control plane, single mesh)
- Anthos Config Management (both clusters configured for the same config repo)
- GKE Connect installed on both clusters

*Note* - This is not an official Google product.

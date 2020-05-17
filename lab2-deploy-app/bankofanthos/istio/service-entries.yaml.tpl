apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: balancereader
  namespace: fsi
  annotations:
    configmanagement.gke.io/cluster-selector: gcp
spec:
  hosts:
  - balancereader.fsi.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  resolution: DNS
  addresses:
  - 240.0.0.2
  endpoints:
  - address: GWIP_ONPREM
    ports:
      http1: 15443 # Do not change this port value
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: ledgerwriter
  namespace: fsi
  annotations:
    configmanagement.gke.io/cluster-selector: gcp
spec:
  hosts:
  - ledgerwriter.fsi.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  resolution: DNS
  addresses:
  - 240.0.0.3
  endpoints:
  - address: GWIP_ONPREM
    ports:
      http1: 15443 # Do not change this port value
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: transactionhistory
  namespace: fsi
  annotations:
    configmanagement.gke.io/cluster-selector: gcp
spec:
  hosts:
  - transactionhistory.fsi.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8080
    protocol: http
  resolution: DNS
  addresses:
  - 240.0.0.4
  endpoints:
  - address: GWIP_ONPREM
    ports:
      http1: 15443 # Do not change this port value
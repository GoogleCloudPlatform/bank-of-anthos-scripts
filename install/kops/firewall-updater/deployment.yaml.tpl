apiVersion: apps/v1
kind: Deployment
metadata:
  name: fwupdater
spec:
  selector:
    matchLabels:
      app: fwupdater
  template:
    metadata:
      labels:
        app: fwupdater
    spec:
      containers:
      - name: main
        image: gcr.io/bank-of-anthos-ci/sme-labs-2020/kops-firewall-updater:latest
        imagePullPolicy: Always
        env:
        - name: PROJECT_ID
          value: MY_PROJECT
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: "/gcp/key.json"
        volumeMounts:
        - name: gac
          mountPath: /gcp/key.json
          subPath: key.json
      volumes:
      - name: gac
        secret:
          secretName: gac
          items:
          - key: gcp
            path: key.json

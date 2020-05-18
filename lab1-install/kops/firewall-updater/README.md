### firewall updater

A python script that continuously updates the https Kops firewall rule to allow kubectl access from cloud shell and cloud build.

#### how to run

1. Create a service account for the updater - give it `firewall admin` permissions

2. Download service account key to your local environment.

3. `export SERVICE_ACCOUNT=/path/to/key.json`

4. Run the updater locally with docker
```
docker run -d -e GOOGLE_APPLICATION_CREDENTIALS="/tmp/serviceaccount.json" -v ${SERVICE_ACCOUNT}:/tmp/serviceaccount.json gcr.io/megandemo/firewall-updater:latest ${PROJECT_ID}
```

# Give the new service account permission to invoke the Execution Service as it is authenticated
gcloud run services add-iam-policy-binding execution-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed

PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')

# Enable the project to create Pub/Sub authentication tokens for authenticated Cloud Run calls
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator

# Create a Pub/Sub subscription for the Execution Service.
export EXECUTION_SERVICE_URL=$(gcloud run services describe execution-service --platform managed --region us-east1 --format="value(status.address.url)")
gcloud pubsub subscriptions create execution-service-sub --topic new-message --push-endpoint=$EXECUTION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

# Give the new service account permission to invoke the Execution Service as it is authenticated
gcloud run services add-iam-policy-binding notification-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed

# Create a Pub/Sub subscription for the Execution Service.
export NOTIFICATION_SERVICE_URL=$(gcloud run services describe notification-service --platform managed --region us-east1 --format="value(status.address.url)")
gcloud pubsub subscriptions create notification-service-sub --topic new-message --push-endpoint=$NOTIFICATION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
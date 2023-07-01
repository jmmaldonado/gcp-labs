### ENABLE APIs AND CREATE PUBSUB TOPIC
gcloud services enable run.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud pubsub topics create new-message


### INSTALL DEPENDENCIES FOR ALL THE SERVICES
cd intake-service
npm install express
npm install body-parser
npm install @google-cloud/pubsub
cd ..

cd execution-service
npm install express
npm install body-parser
cd ..

cd notification-service
npm install express
npm install body-parser
cd ..


### DEPLOY INTAKE SERVICE
cd intake-service
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service
  
gcloud run deploy intake-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --max-instances=1
cd ..


### DEPLOY EXECUTION SERVICE
cd execution-service
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service

gcloud run deploy execution-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1
cd ..


### DEPLOY NOTIFICATION SERVICE
cd notification-service
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/notification-service

gcloud run deploy notification-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/notification-service \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1
cd ..


### CAPTURE SERVICES URLS AND PROJECT NUMBER
export INTAKE_SERVICE_URL=$(gcloud run services describe intake-service --platform managed --region us-east1 --format="value(status.address.url)")
export EXECUTION_SERVICE_URL=$(gcloud run services describe execution-service --platform managed --region us-east1 --format="value(status.address.url)")
export NOTIFICATION_SERVICE_URL=$(gcloud run services describe notification-service --platform managed --region us-east1 --format="value(status.address.url)")
export PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')


### CREATE A SERVICE ACCOUNT TO INVOKE CLOUD RUN SERVICES, GRANT IAM PERMISSIONS TO CREATE TOKENS AND INVOKE CLOUD RUN
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
gcloud run services add-iam-policy-binding execution-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed
gcloud run services add-iam-policy-binding notification-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed


### ENABLE PUB SUB SERVICE AGENT TO CREATE AUTH TOKENS TO ISSUE AUTHENTICATED CALLS TO CLOUD RUN
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator


### CREATE PUB/SUB SUBSCRIPTIONS FOR THE EXECUTION AND NOTIFICATION SERVICES
gcloud pubsub subscriptions create execution-service-sub --topic new-message --push-endpoint=$EXECUTION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
gcloud pubsub subscriptions create notification-service-sub --topic new-message --push-endpoint=$NOTIFICATION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
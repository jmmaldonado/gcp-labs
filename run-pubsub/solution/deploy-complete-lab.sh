### ENABLE APIs
gcloud services enable run.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable cloudbuild.googleapis.com


### CLONE GITHUB REPO
cd ~
git clone https://github.com/jmmaldonado/gcp-labs.git


### INSTALL DEPENDENCIES FOR THE APPLICATION CODE
cd ~/gcp-labs/run-pubsub/solution
cd intake-service && npm install express body-parser @google-cloud/pubsub && cd ..
cd execution-service && npm install express body-parser && cd ..
cd notification-service && npm install express body-parser && cd ..


### DEPLOY INTAKE SERVICE
cd intake-service
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service
gcloud run deploy intake-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --max-instances=1
cd ..


### DEPLOY EXECUTION SERVICE
cd execution-service
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service
gcloud run deploy execution-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1
cd ..


### DEPLOY NOTIFICATION SERVICE
cd notification-service
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/notification-service
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
export PROJECT_NUMBER=$(gcloud projects list --filter="$GOOGLE_CLOUD_PROJECT" --format='value(PROJECT_NUMBER)')


### CREATE PUBSUB TOPIC
gcloud pubsub topics create new-message


### ASSIGN pubsub.publish PERMISSIONS TO THE DEFAULT SERVICE ACCOUNT (CLOUD RUN USES IT) TO THAT TOPIC
gcloud pubsub topics add-iam-policy-binding projects/$GOOGLE_CLOUD_PROJECT/topics/new-message --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com --role=roles/pubsub.publisher


### CREATE A SERVICE ACCOUNT TO INVOKE CLOUD RUN SERVICES, GRANT IAM PERMISSIONS TO CREATE TOKENS AND INVOKE CLOUD RUN
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
gcloud run services add-iam-policy-binding execution-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed
gcloud run services add-iam-policy-binding notification-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region us-east1 --platform managed


### ENABLE PUB SUB SERVICE AGENT TO CREATE AUTH TOKENS TO ISSUE AUTHENTICATED CALLS TO CLOUD RUN
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator


### SEND SOME SAMPLE MESSAGES TO THE INTAKE SERVICE
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 12}" $INTAKE_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 34}" $INTAKE_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 56}" $INTAKE_SERVICE_URL &


### CHECK INTAKE SERVICE LOGS TO SEE THE HTTP 204 CODES (MESSAGE SENT SUCCESSFULLY)
gcloud beta run services logs read intake-service --limit 20 --project $GOOGLE_CLOUD_PROJECT --region us-east1


### CREATE PUB/SUB SUBSCRIPTIONS FOR THE EXECUTION AND NOTIFICATION SERVICES
gcloud pubsub subscriptions create execution-service-sub --topic new-message --push-endpoint=$EXECUTION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
gcloud pubsub subscriptions create notification-service-sub --topic new-message --push-endpoint=$NOTIFICATION_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com


### SEND SOME MORE SAMPLE MESSAGES TO THE INTAKE SERVICE AND SEE IF THEY HIT THE OTHER TWO SERVICES
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 12}" $INTAKE_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 34}" $INTAKE_SERVICE_URL &
curl -X POST -H "Content-Type: application/json" -d "{\"id\": 56}" $INTAKE_SERVICE_URL &


### CHECK INTAKE SERVICE LOGS TO SEE THE HTTP 204 CODES (MESSAGE SENT SUCCESSFULLY)
gcloud beta run services logs read intake-service --limit 20 --project $GOOGLE_CLOUD_PROJECT --region us-east1
gcloud beta run services logs read execution-service --limit 20 --project $GOOGLE_CLOUD_PROJECT --region us-east1
gcloud beta run services logs read notification-service --limit 20 --project $GOOGLE_CLOUD_PROJECT --region us-east1


### DELETE EVERYTHING
gcloud run services delete intake-service --region us-east1 --quiet
gcloud run services delete execution-service --region us-east1 --quiet
gcloud run services delete notification-service --region us-east1 --quiet
gcloud pubsub topics delete new-message --quiet
gcloud pubsub subscriptions delete execution-service-sub
gcloud pubsub subscriptions delete notification-service-sub
gcloud projects remove-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
gcloud iam service-accounts delete pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --quiet

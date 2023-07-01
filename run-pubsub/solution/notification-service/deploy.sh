npm install express
npm install body-parser

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/notification-service

gcloud run deploy notification-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/notification-service \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1
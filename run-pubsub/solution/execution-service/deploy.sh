npm install express
npm install body-parser

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service

gcloud run deploy execution-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/execution-service \
  --platform managed \
  --region us-east1 \
  --no-allow-unauthenticated \
  --max-instances=1
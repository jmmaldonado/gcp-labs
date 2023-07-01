npm install express
npm install body-parser
npm install @google-cloud/pubsub

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service
  
gcloud run deploy intake-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/intake-service \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --max-instances=1
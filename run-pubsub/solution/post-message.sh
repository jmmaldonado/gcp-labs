export INTAKE_SERVICE_URL=$(gcloud run services describe intake-service --platform managed --region us-east1 --format="value(status.address.url)")

curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 12}" \
  $INTAKE_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 34}" \
  $INTAKE_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 56}" \
  $INTAKE_SERVICE_URL &
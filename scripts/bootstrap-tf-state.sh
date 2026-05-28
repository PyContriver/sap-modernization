#!/usr/bin/env bash
# One-time: create S3 bucket + DynamoDB table for Terraform remote state
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
BUCKET="${TF_STATE_BUCKET:-sap-modernization-tfstate-demo}"
TABLE="${TF_LOCK_TABLE:-sap-modernization-tflock-demo}"

echo "Creating S3 bucket ${BUCKET} in ${REGION}..."
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "Bucket already exists."
else
  if [[ "${REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  aws s3api put-bucket-versioning --bucket "${BUCKET}" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "${BUCKET}" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

echo "Creating DynamoDB lock table ${TABLE}..."
aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" 2>/dev/null || \
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

echo "Done. Copy terraform/backend.tf.example to backend.tf and set bucket/table names."

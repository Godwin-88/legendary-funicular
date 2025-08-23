# Outputs for the staging environment

output "mlflow_s3_bucket_name" {
  description = "The name of the S3 bucket for MLflow artifacts."
  value       = aws_s3_bucket.mlflow_artifacts.id
}

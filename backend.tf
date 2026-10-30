# Remote State Backend Configuration
# State is stored in the S3 bucket created by bootstrap/
# Values are supplied at init time from backend-<env>.hcl, so dev and prod get separate state files:
#   terraform init -backend-config=backend-prod.hcl

terraform {
  backend "s3" {}
}

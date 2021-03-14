variable "profile" {
  default     = null
  description = "(Optional) This is the AWS profile name as set in the shared credentials file."
}
variable "region" {
  description = "(Required) This is the AWS region. It must be provided, but it can also be sourced from the AWS_DEFAULT_REGION environment variables, or via a shared credentials file if profile is specified."
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

output "caller" { value = data.aws_caller_identity.current }
output "region" { value = data.aws_region.current }

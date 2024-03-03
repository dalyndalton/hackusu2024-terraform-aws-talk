
provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "dx2-tf-state"
    key    = "p3-reusing-resources"
    region = "us-west-2"
  }
}

locals {
  lambda_names = [for i in range(1, 26) : format("lambda-%02d", i)]
}


module "lambda_example" {
  for_each        = toset(local.lambda_names)
  source          = "./lambda-with-url"
  archive_path    = "./lambda.zip"
  name            = each.key
  description     = "this is lambda ${each.key}"
  lambda_role_arn = aws_iam_role.lambda_role.arn #  defined below, and shared
}

########################################################################################################################
# IAM ROLE PERMISSIONS
########################################################################################################################

# We only create these once because each lambda can share them

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create the initial iam role for the lambda to use
resource "aws_iam_role" "lambda_role" {
  name               = "numbered_lambda_aws"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Defines the permissions set for the log stream
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# Create a basic policy for logging from a lambda using the definition above
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging_numbered"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

# Attach the policy to our simple role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

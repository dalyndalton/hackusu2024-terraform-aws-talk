########################################################################################################################
# BUILD
########################################################################################################################
locals {
  binary_path  = "${path.module}/../bin/bootstrap"
  archive_path = "${path.module}/../bin/lambda.zip"
  src_path     = "${path.module}/../cmd/lambda.go"
}

// build the binary for the lambda function in a specified path
resource "null_resource" "function_binary" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "GOOS=linux GOARCH=arm64 CGO_ENABLED=0 GOFLAGS=-trimpath go build -mod=readonly -ldflags='-s -w' -o ${local.binary_path} ${local.src_path}"
  }
}

// zip the binary, as we can use only zip files to AWS lambda
data "archive_file" "function_archive" {
  depends_on = [null_resource.function_binary]

  type        = "zip"
  source_file = local.binary_path
  output_path = local.archive_path
}

########################################################################################################################
# LAMBDA DEFINITIONS
########################################################################################################################

resource "aws_lambda_function" "simple_webserver" {
  function_name = var.super_secret_name
  description   = "A simple example webserver deployed to lambda, that reads / writes data to dynamo"
  role          = aws_iam_role.simple_webserver.arn

  architectures    = ["arm64"] # Runs on aws graviton, which is faster, cheaper, and cooler 😎
  runtime          = "provided.al2023"
  handler          = "bootstrap"
  filename         = local.archive_path
  source_code_hash = data.archive_file.function_archive.output_base64sha256
}

# Define a url for lambda to send / recieve requests from
resource "aws_lambda_function_url" "public_endpoint" {
  function_name      = aws_lambda_function.simple_webserver.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

# Stores logs for the function for 2 weeks
resource "aws_cloudwatch_log_group" "simple_webserver_logging" {
  name              = "/aws/lambda/${aws_lambda_function.simple_webserver.function_name}"
  retention_in_days = 14
}

########################################################################################################################
# IAM ROLE PERMISSIONS
########################################################################################################################

# What why? Why are we making a lambda become itself
# A: This lets your lambda obtain temporary credentials related to its role
#    Meaning that you don't have to manually call `aws sts get-token` to authenticate
#    with aws resources
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
resource "aws_iam_role" "simple_webserver" {
  name               = "simple_webserver"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# gives the lambda read & write access to our dynamodb table
resource "aws_iam_role_policy_attachment" "simple_webserver_storage_access" {
  role       = aws_iam_role.simple_webserver.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
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
  name        = "lambda_logging"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

# Attach the policy to our simple role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.simple_webserver.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

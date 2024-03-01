
resource "aws_lambda_function" "simple_webserver" {
  function_name = "simple_webserver"
  description   = "A simple example webserver deployed to lambda, that reads / writes data to dynamo"
  role          = aws_iam_role.simple_webserver.arn

  architectures = ["arm64"] # Runs on aws graviton, which is faster, cheaper, and more environmentally friendly
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  filename      = "${path.module}/../bin/bootstrap.zip"
}

# Define a url for lambda to send / recieve requests from
resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.simple_webserver.function_name
  authorization_type = "NONE"
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
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

# Attach the policy to our simple role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.simple_webserver.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

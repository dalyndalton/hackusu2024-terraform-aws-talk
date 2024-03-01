resource "aws_lambda_function" "lambda" {
  function_name = var.name
  description   = var.description
  role          = var.lambda_role_arn

  architectures = ["arm64"] # Runs on aws graviton, which is faster, cheaper, and more environmentally friendly
  runtime       = "provided.al2023"
  handler       = "bootstrap"
  filename      = var.archive_path

}

# Define a url for lambda to send / recieve requests from
resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.lambda.function_name
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

resource "aws_cloudwatch_log_group" "simple_webserver_logging" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}

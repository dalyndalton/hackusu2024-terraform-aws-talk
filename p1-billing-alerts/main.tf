provider "aws" {
  region = "us-east-1" # CloudWatch billing metrics are only available in us-east-1
}

# Dont worry about this
terraform {
  backend "s3" {
    bucket = "dx2-tf-state"
    key    = "p1-billing-alerts-lambda"
    region = "us-west-2"
  }
}

# We need an email to alert on, thats this value
variable "email_address" {
  type = string
}

resource "aws_budgets_budget" "monthly" {
  name         = "budget-monthly"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.email_address]
    subscriber_sns_topic_arns  = [aws_sns_topic.billing_alerts.arn]
  }
}

### DONT LOOK DOWN HERE ITS NOT NEEDED





























resource "aws_sns_topic" "billing_alerts" {
  name = "billing-alerts"
}

########################################################################################################################
# Permission for the budget to fire the SNS
########################################################################################################################


# Give permissions to push to the SNS
data "aws_iam_policy_document" "budgets_sns_publish_policy_doc" {
  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.billing_alerts.arn] # Replace <SNS_TOPIC_ARN> with your SNS topic ARN

    effect = "Allow"
  }

}
resource "aws_iam_policy" "budgets_sns_publish_policy" {
  name        = "budgets_sns_publish_policy"
  description = "Allow AWS Budgets to publish alerts to SNS topic"
  policy      = data.aws_iam_policy_document.budgets_sns_publish_policy_doc.json
}

# Policy to allow the budget trigger to recieve the correct permissions
data "aws_iam_policy_document" "budgets_assume_role_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    effect = "Allow"
  }
}
resource "aws_iam_role" "budgets_sns_publish_role" {
  name               = "budgets_sns_publish_role"
  assume_role_policy = data.aws_iam_policy_document.budgets_assume_role_policy_doc.json
}

# Allow budget alert iam to use the policy defined earlier
resource "aws_iam_role_policy_attachment" "budgets_sns_publish_attachment" {
  role       = aws_iam_role.budgets_sns_publish_role.name
  policy_arn = aws_iam_policy.budgets_sns_publish_policy.arn
}

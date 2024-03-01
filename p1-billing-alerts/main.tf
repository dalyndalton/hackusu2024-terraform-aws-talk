provider "aws" {
  region = "us-east-1" # CloudWatch billing metrics are only available in us-east-1
}

resource "aws_budgets_budget" "monthly" {
  name         = "budget-monthly"
  budget_type  = "COST"
  limit_amount = "1"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.billing_alerts.arn]
  }
}

resource "aws_sns_topic" "billing_alerts" {
  name = "billing-alerts"
}

resource "aws_sns_topic_subscription" "billing_alert_email" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = "dalyn.dalton.dd@gmail.com"
}

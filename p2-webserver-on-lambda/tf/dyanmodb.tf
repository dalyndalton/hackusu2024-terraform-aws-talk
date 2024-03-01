resource "aws_dynamodb_table" "storage_table" {
  name         = "simple_webserver_storage"
  billing_mode = "PAY_PER_REQUEST"


  hash_key  = "IPAddress"

  attribute {
    name = "IPAddress"
    type = "S"
  }
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "${aws_dynamodb_table.storage_table.arn}"
    ]
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "simple-webserver-access"
  description = "Allows Read / Writes for a given webserver"
  policy      = data.aws_iam_policy_document.dynamodb_access.json
}

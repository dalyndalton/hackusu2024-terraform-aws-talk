# Define the table and
resource "aws_dynamodb_table" "storage_table" {
  name         = "simple_webserver_storage"
  billing_mode = "PAY_PER_REQUEST"


  hash_key = "IPAddress"

  # Its NOSQL, so only define the attributes that are needed for hashes or secondary sort keys
  attribute {
    name = "IPAddress"
    type = "S"
  }
}


# Tells aws how and what permissions you have on the resource
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

# Creates an iam role with the permissions defined above
resource "aws_iam_policy" "dynamodb_access" {
  name        = "simple-webserver-access"
  description = "Allows Read / Writes for a given webserver"
  policy      = data.aws_iam_policy_document.dynamodb_access.json
}

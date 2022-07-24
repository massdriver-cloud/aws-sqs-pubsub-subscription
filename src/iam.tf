locals {
  _subscriber_statement = [{
    Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    Effect   = "Allow"
    Resource = aws_sqs_queue.main.arn
  }]

  _dlq_statement = [{
    Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    Effect   = "Allow"
    Resource = aws_sqs_queue.dlq.arn
  }]

  _kms_decrypt_statement = local.is_multi_region ? [{
    Action   = ["kms:Decrypt"]
    Effect   = "Allow"
    Resource = module.kms_key[0].key_arn
  }] : []

  subscriber_statement = flatten([local._subscriber_statement, local._kms_decrypt_statement])
  dlq_statement        = flatten([local._dlq_statement, local._kms_decrypt_statement])
}

resource "aws_iam_policy" "subscriber" {
  name        = "${local.name}-subscriber"
  description = "SQS Pub/Sub subscriber policy: ${local.name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.subscriber_statement
  })
}

resource "aws_iam_policy" "dlq_subscriber" {
  name        = "${local.name}-dlq-subscriber"
  description = "SQS Pub/Sub dead-letter queue policy: ${local.name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.dlq_statement
  })
}

locals {
  _subscribe_statement = [{
    Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    Effect   = "Allow"
    Resource = aws_sqs_queue.main.arn
  }]

  _dlq_statement = [{
    Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    Effect   = "Allow"
    Resource = aws_sqs_queue.dlq.arn
  }]

  _kms_decrypt_statement = local.is_multi_region ? [{
    Action   = ["kms:Decrypt"]
    Effect   = "Allow"
    Resource = module.kms_key[0].key_arn
  }] : []

  subscribe_statement = flatten([local._subscribe_statement, local._kms_decrypt_statement])
  dlq_statement       = flatten([local._dlq_statement, local._kms_decrypt_statement])
}

resource "aws_iam_policy" "subscribe" {
  name        = "${local.name}-subscribe"
  description = "SQS Pub/Sub subscribe policy: ${local.name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.subscribe_statement
  })
}

resource "aws_iam_policy" "dlq_subscribe" {
  name        = "${local.name}-dlq-subscribe"
  description = "SQS Pub/Sub dead-letter queue policy: ${local.name}"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.dlq_statement
  })
}

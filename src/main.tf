
locals {
  fifo_ext                = ".fifo"
  is_fifo                 = try(regex(".fifo$", var.topic.data.infrastructure.arn) == local.fifo_ext, false)
  is_multi_region         = (var.queue.region != var.topic.specs.aws.region)
  name                    = var.md_metadata.name_prefix
  dlq_name                = "${var.md_metadata.name_prefix}-dlq"
  dlq_name_with_extension = local.is_fifo ? "${local.dlq_name}${local.fifo_ext}" : local.dlq_name
  name_with_extension     = local.is_fifo ? "${local.name}${local.fifo_ext}" : local.name
  kms_key_id              = local.is_multi_region ? module.kms_key[0].key_arn : null
}

resource "aws_sqs_queue" "main" {
  name                        = local.name_with_extension
  fifo_queue                  = local.is_fifo
  sqs_managed_sse_enabled     = local.is_multi_region ? null : true
  content_based_deduplication = false
  visibility_timeout_seconds  = var.queue.visibility_timeout_seconds
  message_retention_seconds   = var.queue.message_retention_seconds
  max_message_size            = var.queue.max_message_size
  kms_master_key_id           = local.kms_key_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  name                        = local.dlq_name_with_extension
  fifo_queue                  = local.is_fifo
  sqs_managed_sse_enabled     = local.is_multi_region ? null : true
  content_based_deduplication = false
  visibility_timeout_seconds  = var.queue.visibility_timeout_seconds
  kms_master_key_id           = local.kms_key_id
  # Set to max time to allow for processing
  message_retention_seconds = 1209600

  # Set to max size in case message is rejected on primary queue for size
  max_message_size = 262144
}

resource "aws_sns_topic_subscription" "main" {
  provider             = aws.topic
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = var.topic.data.infrastructure.arn
  endpoint             = aws_sqs_queue.main.arn
}

data "aws_iam_policy_document" "queue_policy" {
  statement {
    sid    = "Allow SNS to SendMessage to this queue"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.main.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${var.topic.data.infrastructure.arn}"]
    }
  }

  dynamic "statement" {
    for_each = length(var.queue.additional_access) > 0 ? [1] : []
    content {
      sid    = "Cross Account Access Policy for SQS Read"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.queue.additional_access
      }
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = [aws_sqs_queue.main.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.queue_policy.json
}

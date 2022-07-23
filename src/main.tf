
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

  policy = jsonencode({
    "Version" = "2008-10-17",
    "Statement" = [
      {
        "Sid"    = "Allow SNS to SendMessage to this queue",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "sns.amazonaws.com"
        },
        "Action"   = "sqs:SendMessage",
        "Resource" = "*",
        "Condition" = {
          "ArnEquals" = {
            "aws:SourceArn" = "${var.topic.data.infrastructure.arn}"
          }
        }
      }
    ]
    }
  )
}

resource "aws_sqs_queue" "dlq" {
  name                        = local.dlq_name_with_extension
  fifo_queue                  = local.is_fifo
  sqs_managed_sse_enabled     = local.is_multi_region ? null : true
  content_based_deduplication = false
  visibility_timeout_seconds  = var.queue.visibility_timeout_seconds
  message_retention_seconds   = 1209600
  max_message_size            = var.queue.max_message_size
  kms_master_key_id           = local.kms_key_id
}

resource "aws_sns_topic_subscription" "main" {
  provider             = aws.topic
  protocol             = "sqs"
  raw_message_delivery = true
  topic_arn            = var.topic.data.infrastructure.arn
  endpoint             = aws_sqs_queue.main.arn
}




# # presets
# # TODO: create a 'subscriber' policy that can be forwarded downstream (dont add a publisher, SNS is your publisher)
# # alarms
# # test redrive

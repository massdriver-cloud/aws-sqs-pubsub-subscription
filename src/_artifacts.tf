resource "massdriver_artifact" "queue" {
  field                = "queue"
  provider_resource_id = aws_sqs_queue.main.arn
  name                 = "AWS SQS Queue: ${local.name}"
  artifact = jsonencode(
    {
      data = {
        infrastructure = {
          arn = aws_sqs_queue.main.arn
        }
        security = {
          iam = {
            subscribe = {
              policy_arn = aws_iam_policy.subscribe.arn
            }
          }
        }
      }
      specs = {
        aws = {
          region = var.queue.region
        }
      }
    }
  )
}

resource "massdriver_artifact" "dlq" {
  field                = "dlq"
  provider_resource_id = aws_sqs_queue.dlq.arn
  name                 = "AWS SQS DLQ: ${local.name}"
  artifact = jsonencode(
    {
      data = {
        infrastructure = {
          arn = aws_sqs_queue.dlq.arn
        }
        security = {
          iam = {
            subscribe = {
              policy_arn = aws_iam_policy.dlq_subscribe.arn
            }
          }
        }
      }
      specs = {
        aws = {
          region = var.queue.region
        }
      }
    }
  )
}

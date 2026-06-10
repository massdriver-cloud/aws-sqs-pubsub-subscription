resource "massdriver_artifact" "queue" {
  field    = "queue"
  name     = "AWS SQS Pub/Sub queue: ${local.name}"
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
  name                 = "AWS SQS dead-letter queue: ${local.name}"
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

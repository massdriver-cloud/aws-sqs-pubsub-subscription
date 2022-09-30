locals {
  automated_alarms = {
    # ApproximateNumberOfMessagesVisible SUM > 0
    dlq_num_messages_visible = {
      threshold = 0
      statistic = "Sum"
      period    = 300
    }

    # ApproximateAgeOfOldestMessage 80% of Max
    main_age_of_oldest_message = {
      # 80% of age
      threshold = floor(var.queue.message_retention_seconds * 0.8)
      statistic = "Maximum"
      period    = 300
    }


    # ApproximateNumberOfMessagesNotVisible Service maximums are 120k / 20k (FIFO)
    main_num_messages_not_visible = {
      threshold = local.is_fifo ? 18000 : 110000
      statistic = "Maximum"
      period    = 300
    }

    # SentMessageSize
    main_sent_message_size = {
      # 90% of size
      threshold = floor(var.queue.max_message_size * 0.9)
      statistic = "Average"
      period    = 300
    }
  }

  # TODO: Support CUSTOM
  alarms = var.monitoring.alarms == "AUTOMATED" ? local.automated_alarms : {}
}

module "alarm_channel" {
  source      = "github.com/massdriver-cloud/terraform-modules//aws-alarm-channel?ref=8997456"
  md_metadata = var.md_metadata
}

module "dlq_num_messages_visible_alarm" {
  count               = lookup(local.alarms, "dlq_num_messages_visible", null) == null ? 0 : 1
  source              = "github.com/massdriver-cloud/terraform-modules//aws-cloudwatch-alarm?ref=8997456"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  metric_name         = "ApproximateNumberOfMessagesVisible"
  display_name        = "Messages Visible in DLQ"
  alarm_name          = "${aws_sqs_queue.dlq.name}-highApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = local.alarms.dlq_num_messages_visible.period
  statistic           = local.alarms.dlq_num_messages_visible.statistic


  threshold = local.alarms.dlq_num_messages_visible.threshold
  message   = "SQS Queue ${aws_sqs_queue.dlq.name}: ${local.alarms.dlq_num_messages_visible.statistic} ApproximateNumberOfMessagesVisible > ${local.alarms.dlq_num_messages_visible.threshold}"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}

module "main_age_of_oldest_message_alarm" {
  count               = lookup(local.alarms, "main_age_of_oldest_message", null) == null ? 0 : 1
  source              = "github.com/massdriver-cloud/terraform-modules//aws-cloudwatch-alarm?ref=8997456"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  metric_name         = "ApproximateAgeOfOldestMessage"
  display_name        = "Age of Oldest Message"
  alarm_name          = "${aws_sqs_queue.main.name}-highApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = local.alarms.main_age_of_oldest_message.period
  statistic           = local.alarms.main_age_of_oldest_message.statistic

  message   = "SQS Queue ${aws_sqs_queue.main.name}: ${local.alarms.main_age_of_oldest_message.statistic} ApproximateAgeOfOldestMessage > ${local.alarms.main_age_of_oldest_message.threshold}"
  threshold = local.alarms.main_age_of_oldest_message.threshold

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }
}


module "main_num_messages_not_visible_threshold_alarm" {
  count               = lookup(local.alarms, "main_num_messages_not_visible", null) == null ? 0 : 1
  source              = "github.com/massdriver-cloud/terraform-modules//aws-cloudwatch-alarm?ref=8997456"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  metric_name         = "ApproximateNumberOfMessagesNotVisible"
  display_name        = "Messages Not Visible"
  alarm_name          = "${aws_sqs_queue.main.name}-highApproximateNumberOfMessagesNotVisible"
  namespace           = "AWS/SQS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = local.alarms.main_num_messages_not_visible.period
  statistic           = local.alarms.main_num_messages_not_visible.statistic

  message   = "SQS Queue ${aws_sqs_queue.main.name}: ${local.alarms.main_num_messages_not_visible.statistic} ApproximateNumberOfMessagesNotVisible > ${local.alarms.main_num_messages_not_visible.threshold}"
  threshold = local.alarms.main_num_messages_not_visible.threshold

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }
}

# Detect messages that over time are getting more data added to them and may go over the set limit
module "main_sent_message_size_alarm" {
  count               = lookup(local.alarms, "main_sent_message_size", null) == null ? 0 : 1
  source              = "github.com/massdriver-cloud/terraform-modules//aws-cloudwatch-alarm?ref=8997456"
  sns_topic_arn       = module.alarm_channel.arn
  md_metadata         = var.md_metadata
  metric_name         = "SentMessageSize"
  display_name        = "Sent Message Size"
  alarm_name          = "${aws_sqs_queue.main.name}-highSentMessageSize"
  namespace           = "AWS/SQS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = local.alarms.main_sent_message_size.period
  statistic           = local.alarms.main_sent_message_size.statistic

  message   = "SQS Queue ${aws_sqs_queue.main.name}: ${local.alarms.main_sent_message_size.statistic} SentMessageSize > ${local.alarms.main_sent_message_size.threshold}"
  threshold = local.alarms.main_sent_message_size.threshold

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }
}

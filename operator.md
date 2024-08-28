## AWS SQS Pub/Sub Subscription

AWS SQS (Simple Queue Service) is a managed messaging queue service that enables you to decouple and scale microservices, distributed systems, and serverless applications. It ensures that your messages are delivered in order and are available until they are processed.

### Design Decisions

1. **Multi-Region Support**: This module is designed to support multiple regions, accommodating a variety of use cases including disaster recovery and latency optimization.
  
2. **Dead-Letter Queue Integration**: It includes a dead-letter queue (DLQ) for handling messages that cannot be processed successfully after a specified number of attempts, enhancing reliability.
  
3. **Automated Alarms**: Automated CloudWatch alarms are set up for critical SQS metrics like message visibility and age of the oldest message, providing proactive monitoring.
  
4. **IAM Policies**: Fine-grained IAM policies are created for granting necessary permissions, ensuring secure access to queues.
  
5. **KMS Encryption**: If configured for multi-region, AWS KMS (Key Management Service) is utilized for additional message encryption.

### Runbook

#### Cannot Receive Messages from SQS Queue

Check if the policies allow the necessary actions.

Verify the IAM policies attached to the roles that are accessing the SQS queue to ensure they have permission to perform the required actions.

```sh
aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-names Policy
```

Ensure the policy includes actions like `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:GetQueueAttributes`.

#### CloudWatch Alarm Triggered for High Number of Visible Messages

Investigate why messages are not being processed and are remaining in the queue.

List the approximate number of messages in the SQS queue.

```sh
aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-names ApproximateNumberOfMessages
```

Check application logs to see if there are issues or errors preventing message processing.

#### AWS CLI: Validate Redrive Policy for Dead-Letter Queue

Check the redrive policy configured for the main SQS queue to ensure messages are being moved to the DLQ after the specified number of receive attempts.

```sh
aws sqs get-queue-attributes --queue-url <QUEUE_URL> --attribute-names RedrivePolicy
```

Confirm the `maxReceiveCount` and `deadLetterTargetArn` are set appropriately.

#### Dead-Letter Queue is Receiving Messages

If messages are frequently sent to the DLQ, this could indicate an issue with message processing in the main queue.

List the messages in the DLQ to identify why they are failing.

```sh
aws sqs receive-message --queue-url <DLQ_QUEUE_URL> --max-number-of-messages 10
```

Examine the contents and look for patterns or common errors.

### Redis Trouble Shooting

#### PING command to check availability

Check if the Redis instance is up and running.

```sh
redis-cli -h <REDIS_HOST> -p <REDIS_PORT> PING
```

You should see a response as `PONG`.

#### Check Memory Usage

Ensure the Redis instance has adequate memory available.

```sh
redis-cli -h <REDIS_HOST> -p <REDIS_PORT> INFO memory
```

Look for `used_memory`, `used_memory_human`, and `maxmemory` attributes.

#### Find Large Keys

Identify if a particular key or set of keys is consuming a lot of space.

```sh
redis-cli -h <REDIS_HOST> -p <REDIS_PORT> --bigkeys
```

Examine the output for large keys and consider their impact on performance.

### MySQL Trouble Shooting

#### Check MySQL Connection

Ensure the MySQL service is up and accepting connections.

```sh
mysqladmin -h <MYSQL_HOST> -u <MYSQL_USER> -p ping
```

You should see a response as `mysqld is alive`.

#### Query Slow Log

Identify slow queries that could be impacting performance.

```sh
mysql -u <MYSQL_USER> -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
mysql -u <MYSQL_USER> -p -e "SHOW VARIABLES LIKE 'long_query_time';"
mysql -u <MYSQL_USER> -p -e "SHOW VARIABLES LIKE 'slow_query_log_file';"
```

Print the slow query log.

```sh
mysql -u <MYSQL_USER> -p -e "SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;"
```

Evaluate the results and consider optimizing identified slow queries.


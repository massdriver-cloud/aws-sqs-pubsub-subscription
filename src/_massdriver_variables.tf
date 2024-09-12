// Auto-generated variable declarations from massdriver.yaml
variable "aws_authentication" {
  type = object({
    data = object({
      arn         = string
      external_id = optional(string)
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}
variable "md_metadata" {
  type = object({
    default_tags = object({
      managed-by  = string
      md-manifest = string
      md-package  = string
      md-project  = string
      md-target   = string
    })
    deployment = object({
      id = string
    })
    name_prefix = string
    observability = object({
      alarm_webhook_url = string
    })
    package = object({
      created_at             = string
      deployment_enqueued_at = string
      previous_status        = string
      updated_at             = string
    })
    target = object({
      contact_email = string
    })
  })
}
variable "monitoring" {
  type = object({
    mode = optional(string)
    alarms = optional(object({
      dlq_num_messages_visible = optional(object({
        period    = number
        threshold = number
      }))
      main_age_of_oldest_message = optional(object({
        period    = number
        threshold = number
      }))
      main_num_messages_not_visible = optional(object({
        period    = number
        threshold = number
      }))
      main_sent_message_size = optional(object({
        period    = number
        threshold = number
      }))
    }))
  })
  default = null
}
variable "queue" {
  type = object({
    additional_access          = optional(list(string))
    max_message_size           = number
    message_retention_seconds  = number
    region                     = string
    visibility_timeout_seconds = number
  })
}
variable "topic" {
  type = object({
    data = object({
      infrastructure = object({
        arn = string
      })
      security = optional(object({
        iam = optional(map(object({
          policy_arn = string
        })))
        identity = optional(object({
          role_arn = optional(string)
        }))
        network = optional(map(object({
          arn      = string
          port     = number
          protocol = string
        })))
      }))
    })
    specs = object({
      aws = optional(object({
        region = optional(string)
      }))
    })
  })
}

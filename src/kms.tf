data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "sns_kms" {
  statement {
    sid = "Allow access to SNS for all principals in the account that are authorized to use SNS"
    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com"
      ]
    }
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow administration of the key"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

module "kms_key" {
  count       = local.is_multi_region ? 1 : 0
  source      = "github.com/massdriver-cloud/terraform-modules//aws/aws-kms-key?ref=7dbcf1e"
  md_metadata = var.md_metadata
  policy      = data.aws_iam_policy_document.sns_kms.json
}

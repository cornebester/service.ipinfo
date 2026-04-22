resource "aws_sns_topic" "spot_termination_notification_topic" {
  name = "spot-termination-notification-topic"
}


resource "aws_sns_topic_policy" "spot_termination_notification_topic" {
  arn = aws_sns_topic.spot_termination_notification_topic.arn

  policy = data.aws_iam_policy_document.spot_termination_notification_topic.json
}

data "aws_iam_policy_document" "spot_termination_notification_topic" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.spot_termination_notification_topic.arn,
    ]

    sid = "__default_statement_ID"
  }
  statement {
    sid = "PublishEventsToMyTopic"
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.spot_termination_notification_topic.arn]
    effect    = "Allow"
  }
}

# https://medium.com/@IT_Sammy/amazon-sns-email-subscription-problems-26e385ced9f5

resource "aws_sns_topic_subscription" "spot_termination_notification_subscription_my_email_custom" {
  topic_arn = aws_sns_topic.spot_termination_notification_topic.arn
  protocol  = "email"
  endpoint  = var.default_spot_notification_email_address
}

resource "aws_iam_role" "Amazon_EventBridge_Invoke_Sns_Spot_Termination_Role" {
  name               = "AmazonEventBridgeInvokeSnsSpotTerminationRole"
  description        = ""
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.Amazon_EventBridge_Invoke_Sns_trust_Policy.json

  tags = {}
}


data "aws_iam_policy_document" "Amazon_EventBridge_Invoke_Sns_trust_Policy" {
  statement {
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/${aws_cloudwatch_event_rule.spot_termination.name}"]
    }

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}



data "aws_iam_policy_document" "Amazon_EventBridge_Invoke_Sns_Policy" {
  statement {
    # sid = "iot"
    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:spot-termination-notification-topic"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "Amazon_EventBridge_Invoke_Sns_Policy" {
  name        = "AmazonEventBridgeInvokeSnsPolicySpotTermination"
  description = "IAM policy for Amazon EventBridge to invoke SNS"
  path        = "/"

  policy = data.aws_iam_policy_document.Amazon_EventBridge_Invoke_Sns_Policy.json

  tags = {}
}

resource "aws_iam_role_policy_attachment" "Amazon_EventBridge_Invoke_Sns_Spot_Termination_Role_attachment" {
  role       = aws_iam_role.Amazon_EventBridge_Invoke_Sns_Spot_Termination_Role.name
  policy_arn = aws_iam_policy.Amazon_EventBridge_Invoke_Sns_Policy.arn
}

data "aws_cloudwatch_event_bus" "default" {
  name = "default"
}

resource "aws_cloudwatch_event_rule" "spot_termination" {
  name        = "spot_termination_rule"
  description = "Rule to capture EC2 Spot Instance termination notifications"

  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "spot_termination_notification_target" {
  rule      = aws_cloudwatch_event_rule.spot_termination.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.spot_termination_notification_topic.arn
}
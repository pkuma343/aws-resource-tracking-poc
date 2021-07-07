provider "aws" {
  region     = var.Region
}
 
resource "aws_iam_role" "lambda_get_resources_role" {
  name = var.lambdaRole
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
           Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_get_resources_policy" {
  name = var.lambdaPolicy
  role = aws_iam_role.lambda_get_resources_role.id
  policy =  jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ses:SendRawEmail",
            "Resource": "arn:aws:ses:*:475600362560:identity/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "ses:VerifyEmailIdentity",
                "ec2:DescribeRegions",
                "ses:ListVerifiedEmailAddresses"
            ],
            "Resource": "*"
        }
    ]
})
}

locals{
    lambda_zip_location = "poc.zip"
}

resource "aws_lambda_function" "lambdaFuncGetResources" {
  filename      = local.lambda_zip_location
  function_name = var.FUNCTION_NAME  
  role = aws_iam_role.lambda_get_resources_role.arn
  handler       = "lambda_handler.lambda_handler"
  environment {
    variables = {
      REGION=var.Region, 
      FROM=var.fromMail,
      FILE=var.file, 
      TO=var.toMail
    }
  }
  timeout = "300"
  memory_size = "512"
  runtime = "python3.7"
}

resource "aws_cloudwatch_event_rule" "get_resources_rule" {
  name                = var.event_rule
  description         = "schedule at regular intervals"
  # schedule_expression = "rate(1 minute)"
  schedule_expression = var.cron
}

resource "aws_cloudwatch_event_target" "get-resources_target_rule" {
  rule      = "${aws_cloudwatch_event_rule.get_resources_rule.name}"
  target_id = "lambda"
  arn       = "${aws_lambda_function.lambdaFuncGetResources.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_target" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambdaFuncGetResources.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.get_resources_rule.arn}"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Schedular" {
  ami           = "ami-014d544cfef21b42d"
  instance_type = "t2.micro"

  tags = {
    Name = "SchedularInstance"
  }
}

output "instance_ids" {
  value = aws_instance.Schedular.id
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_ec2_scheduler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_ec2_scheduler_policy"
  role   = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_lambda_function" "start_instances" {
  filename         = "lambda_start.zip"
  function_name    = "start_ec2_instances"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_start.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_start.zip")
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID = "i-0a1572df1cd08d086"
    }
  }
}

resource "aws_lambda_function" "stop_instances" {
  filename         = "lambda_stop.zip"
  function_name    = "stop_ec2_instances"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_stop.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_stop.zip")
  timeout          = 30

  environment {
    variables = {
      INSTANCE_ID = "i-0a1572df1cd08d086"
    }
  }
}

resource "aws_cloudwatch_event_rule" "start_rule" {
  name                = "start_instance_rule"
  schedule_expression = "cron(0 8 * * ? *)"  # 8:00 AM every day
}

resource "aws_cloudwatch_event_rule" "stop_rule" {
  name                = "stop_instance_rule"
  schedule_expression = "cron(0 17 * * ? *)"  # 5:00 PM every day
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_rule.name
  target_id = "start_ec2_instances"
  arn       = aws_lambda_function.start_instances.arn
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_rule.name
  target_id = "stop_ec2_instances"
  arn       = aws_lambda_function.stop_instances.arn
}

resource "aws_lambda_permission" "allow_start" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rule.arn
}

resource "aws_lambda_permission" "allow_stop" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rule.arn
}
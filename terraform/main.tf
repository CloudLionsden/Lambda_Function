# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "snapshot_vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "snapshot-cleanup-vpc"
  }
}

# -------------------------
# Private Subnet
# -------------------------
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.snapshot_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "snapshot-private-subnet"
  }
}

# -------------------------
# Private Route Table
# -------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.snapshot_vpc.id

  tags = {
    Name = "snapshot-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------
# Security Group for Lambda
# -------------------------
resource "aws_security_group" "lambda_sg" {
  name        = "snapshot-cleanup-lambda-sg"
  description = "Allow Lambda outbound access"
  vpc_id      = aws_vpc.snapshot_vpc.id

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "snapshot-cleanup-lambda-sg"
  }
}

# -------------------------
# IAM Role for Lambda
# -------------------------
resource "aws_iam_role" "lambda_role" {
  name = "snapshot-cleanup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# -------------------------
# IAM Policy (Least Privilege)
# -------------------------
resource "aws_iam_policy" "lambda_policy" {
  name        = "snapshot-cleanup-policy"
  description = "Permissions for Lambda snapshot cleanup"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSnapshots",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -------------------------
# Lambda Function
# -------------------------
resource "aws_lambda_function" "snapshot_cleanup" {
  function_name = "snapshot-cleanup"
  role          = aws_iam_role.lambda_role.arn

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"
  timeout = 60

  filename         = "../lambda/lambda.zip"
  source_code_hash = filebase64sha256("../lambda/lambda.zip")

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      RETENTION_DAYS = tostring(var.retention_days)
    }
  }

  tags = {
    Name = "snapshot-cleanup"
  }
}

# -------------------------
# EventBridge Scheduled Rule (Daily)
# -------------------------
resource "aws_cloudwatch_event_rule" "daily_rule" {
  name                = "snapshot-cleanup-daily"
  description         = "Triggers Lambda daily to delete old snapshots"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_rule.name
  target_id = "snapshot-cleanup"
  arn       = aws_lambda_function.snapshot_cleanup.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rule.arn
}

# -------------------------
# OPTIONAL BUT IMPORTANT:
# VPC Endpoint for EC2 API
# -------------------------
resource "aws_vpc_endpoint" "ec2_endpoint" {
  vpc_id            = aws_vpc.snapshot_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.private_subnet.id]
  security_group_ids = [aws_security_group.lambda_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "snapshot-ec2-endpoint"
  }
}


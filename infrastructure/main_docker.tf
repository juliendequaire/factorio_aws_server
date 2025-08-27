terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "factorio_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "factorio-vpc"
  }
}

resource "aws_internet_gateway" "factorio_igw" {
  vpc_id = aws_vpc.factorio_vpc.id

  tags = {
    Name = "factorio-igw"
  }
}

resource "aws_subnet" "factorio_subnet" {
  vpc_id                  = aws_vpc.factorio_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "factorio-subnet"
  }
}

resource "aws_route_table" "factorio_rt" {
  vpc_id = aws_vpc.factorio_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.factorio_igw.id
  }

  tags = {
    Name = "factorio-rt"
  }
}

resource "aws_route_table_association" "factorio_rta" {
  subnet_id      = aws_subnet.factorio_subnet.id
  route_table_id = aws_route_table.factorio_rt.id
}

resource "aws_security_group" "factorio_sg" {
  name        = "factorio-sg"
  description = "Security group for Factorio Docker server"
  vpc_id      = aws_vpc.factorio_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Factorio"
    from_port   = 34197
    to_port     = 34197
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "factorio-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "factorio_ec2_role" {
  name = "factorio-ec2-docker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "factorio_ec2_policy" {
  name = "factorio-ec2-docker-policy"
  role = aws_iam_role.factorio_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "factorio_ec2_ssm" {
  role       = aws_iam_role.factorio_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "factorio_profile" {
  name = "factorio-docker-profile"
  role = aws_iam_role.factorio_ec2_role.name
}

resource "aws_key_pair" "factorio_key" {
  key_name   = "factorio-docker-key"
  public_key = var.public_key
}

resource "aws_instance" "factorio_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.factorio_key.key_name
  vpc_security_group_ids = [aws_security_group.factorio_sg.id]
  subnet_id              = aws_subnet.factorio_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.factorio_profile.name

  user_data = file("${path.module}/user_data_docker.sh")

  tags = {
    Name = "factorio-docker-server"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "factorio-lambda-docker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "factorio-lambda-docker-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/src/lambda_function_docker.py"
  output_path = "${path.module}/lambda_function_docker.zip"
}

resource "aws_lambda_function" "factorio_controller" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "factorio-docker-controller"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function_docker.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      INSTANCE_ID = aws_instance.factorio_server.id
    }
  }
}

resource "aws_api_gateway_rest_api" "factorio_api" {
  name        = "factorio-docker-api"
  description = "API for Factorio Docker server management"
}

resource "aws_api_gateway_resource" "factorio_resource" {
  rest_api_id = aws_api_gateway_rest_api.factorio_api.id
  parent_id   = aws_api_gateway_rest_api.factorio_api.root_resource_id
  path_part   = "server"
}

resource "aws_api_gateway_resource" "action_resource" {
  rest_api_id = aws_api_gateway_rest_api.factorio_api.id
  parent_id   = aws_api_gateway_resource.factorio_resource.id
  path_part   = "{action}"
}

resource "aws_api_gateway_method" "factorio_method" {
  rest_api_id   = aws_api_gateway_rest_api.factorio_api.id
  resource_id   = aws_api_gateway_resource.action_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.factorio_api.id
  resource_id = aws_api_gateway_resource.action_resource.id
  http_method = aws_api_gateway_method.factorio_method.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.factorio_controller.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.factorio_controller.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.factorio_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "factorio_deployment" {
  depends_on = [
    aws_api_gateway_method.factorio_method,
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.factorio_api.id
  stage_name  = "prod"
}
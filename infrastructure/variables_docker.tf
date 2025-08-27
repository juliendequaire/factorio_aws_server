variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (t3.small recommended for Docker setup)"
  type        = string
  default     = "t3.small"
}

variable "public_key" {
  description = "Public key for EC2 instance"
  type        = string
}

variable "enable_docker_optimization" {
  description = "Enable Docker-based optimization features"
  type        = bool
  default     = true
}
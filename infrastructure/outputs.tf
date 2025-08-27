output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.factorio_server.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.factorio_server.public_ip
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "${aws_api_gateway_rest_api.factorio_api.execution_arn}/prod/server"
}

output "factorio_server_address" {
  description = "Factorio server address"
  value       = "${aws_instance.factorio_server.public_ip}:34197"
}
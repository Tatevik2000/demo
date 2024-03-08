output "parameter_name" {
  description = "The name of the SSM parameter"
  value       = aws_ssm_parameter.example.name
}

output "parameter_type" {
  description = "The type of the SSM parameter"
  value       = aws_ssm_parameter.example.type
}

output "ssm_parameter_arn" {
  description = "The ARN of the SSM parameter"
  value       = aws_ssm_parameter.example.arn
}

output "ssm_parameter_value" {
  description = "The value of the SSM parameter (sensitive information)"
  value       = aws_ssm_parameter.example.value
  sensitive   = true
}

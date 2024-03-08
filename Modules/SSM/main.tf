resource "aws_ssm_parameter" "example" {
  name        = var.name
  description = var.description
  type        = var.type
  value       = var.value
  key_id      = var.type == "SecureString" ? var.key_id : null

  lifecycle {
    ignore_changes = [value]
  }
}

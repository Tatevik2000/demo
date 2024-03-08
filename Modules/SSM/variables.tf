variable "name" {
  description = "The name of the parameter"
  type        = string
}

variable "value" {
  description = "The value of the parameter"
  type        = string
}

variable "type" {
  description = "The type of the parameter (String, StringList, SecureString)"
  type        = string
  default     = "String"
}

variable "description" {
  description = "The description of the parameter"
  type        = string
  default     = "Managed by Terraform"
}

variable "key_id" {
  description = "The KMS key ID for encrypting a SecureString parameter"
  type        = string
  default     = ""
}

variable "name" {  
  description = "The name of the ECS task definition"  
  type        = string  
}  
  
variable "cpu" {  
  description = "The number of CPU units used by the task"  
  type        = string  
}  
  
variable "memory" {  
  description = "The amount of memory used by the task (in MiB)"  
  type        = string  
}  
  
variable "execution_role_arn" {  
  description = "The ARN of the role that the ECS tasks can assume"  
  type        = string  
}  
  
variable "task_role_arn" {  
  description = "The ARN of the role that the ECS task can assume"  
  type        = string  
}  
  
variable "container_name" {  
  description = "The name of the container in the task definition"  
  type        = string  
}  
  
variable "docker_image_url" {  
  description = "The URL of the Docker image for the container"  
  type        = string  
}  
  
variable "container_cpu" {  
  description = "The number of CPU units used by the container"  
  type        = number  
}  
  
variable "container_memory" {  
  description = "The amount of memory used by the container (in MiB)"  
  type        = number  
}  
  
variable "container_port" {  
  description = "The port number on the container"  
  type        = number  
}  
  
variable "aws_region" {  
  description = "The AWS region where the log group will be created"  
  type        = string  
}  

variable "environment_variables" {
  description = "A list of maps containing environment variables for the container"
  type        = list(map(string))
  default     = []
}

variable "secrets" {
  description = "List of secrets to include in the task definition"
  type = list(object({
    name = string
    arn  = string
  }))
  default = []
}

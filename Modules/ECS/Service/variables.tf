variable "desired_tasks" {  
  description = "The number of desired tasks to run in the ECS service"  
  type        = number  
}  
  
variable "ecs_cluster_id" {  
  description = "The ID of the ECS cluster"  
  type        = string  
}  
  
variable "arn_task_definition" {  
  description = "The ARN of the ECS task definition"  
  type        = string  
}  
  
variable "security_group_ids" {  
  description = "The list of security group IDs to associate with the ECS service"  
  type        = list(string)  
}  
  
variable "subnet_ids" {  
  description = "The list of subnet IDs for the ECS service"  
  type        = list(string)  
}  
  
variable "target_group_arn" {  
  description = "The ARN of the target group for the ECS service"  
  type        = string  
}  

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
  description = "The port number on the container bound to the host port"  
  type        = number  
}  
  
variable "aws_region" {  
  description = "The AWS region where the log group will be created"  
  type        = string  
}  

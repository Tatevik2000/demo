output "arn_role" {  
  value = var.create_ecs_role && length(aws_iam_role.ecs_task_excecution_role) > 0 ? aws_iam_role.ecs_task_excecution_role[0].arn : ""  
}  
  
output "name_role" {  
  value = var.create_ecs_role && length(aws_iam_role.ecs_task_excecution_role) > 0 ? aws_iam_role.ecs_task_excecution_role[0].name : ""  
}

output "arn_role_ecs_task_role" {
  value = (var.create_ecs_role == true
    ? (length(aws_iam_role.ecs_task_role) > 0 ? aws_iam_role.ecs_task_role[0].arn : "")
  : "")
}

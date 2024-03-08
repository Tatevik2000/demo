resource "aws_ecs_service" "ecs_service" {  
  name                              = "Service-${var.name}"  
  cluster                           = var.ecs_cluster_id  
  task_definition                   = var.arn_task_definition   
  desired_count                     = var.desired_tasks  
  health_check_grace_period_seconds = 60 
  launch_type                       = "FARGATE"  
  
  network_configuration {      
    security_groups = var.security_group_ids   
    subnets         = var.subnet_ids           
  }  
  
  load_balancer {  
    target_group_arn = var.target_group_arn 
    container_name   = var.container_name  
    container_port   = var.container_port  
  }  
  
  lifecycle {  
    ignore_changes = [  
      desired_count,   
      task_definition, 
      load_balancer  
    ]  
  }  

}  

resource "aws_ecs_task_definition" "ecs_task_definition" {  
  family                   = "task-definition-${var.name}"  
  network_mode             = "awsvpc"  
  requires_compatibilities = ["FARGATE"]  
  cpu                      = var.cpu  
  memory                   = var.memory  
  execution_role_arn       = var.execution_role_arn  
  task_role_arn            = var.task_role_arn  
  
  container_definitions = jsonencode([{  
    "name": var.container_name,  
    "image": var.docker_image_url,
    "cpu": var.container_cpu,  
    "memory": var.container_memory,  
    "essential": true,  
    "portMappings": [{  
      "containerPort": var.container_port,  
      "hostPort": var.container_port  
    }],  
    "logConfiguration": {  
      "logDriver": "awslogs",  
      "options": {  
        "awslogs-group": aws_cloudwatch_log_group.ecs_log_group.name,  
        "awslogs-region": var.aws_region, 
        "awslogs-stream-prefix": "ecs"  
      }  
    },
    "environment": [
          for env in var.environment_variables : {
            "name"  = env.name
            "value" = env.value
          }
    ],
    secrets   = [for s in var.secrets : {
          name      = s.name
          valueFrom = s.arn
        }]
  }])  
}  
  
resource "aws_cloudwatch_log_group" "ecs_log_group" {  
  name              = "/ecs/task-definition-${var.name}"  
  retention_in_days = 30  
}  

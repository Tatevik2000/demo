<<<<<<< HEAD
resource "random_id" "RANDOM_ID" {
  byte_length = "2"
}

# ------- Account ID -------
data "aws_caller_identity" "id_current_account" {}

# ------- vpc -------
module "vpc" {
  source = "./Modules/vpc"
  cidr   = ["10.120.0.0/16"]
  name   = var.environment_name
}

# ------- Creating Target Group for the server ALB blue environment -------
module "target_group_server_blue" {
  source              = "./Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-s-b"
  port                = 80
  protocol            = "HTTP"
  vpc                 = module.vpc.aws_vpc
  tg_type             = "ip"
  health_check_path   = "/status"
  health_check_port   = var.port_app_server
}

# ------- Creating Target Group for the server ALB green environment -------
module "target_group_server_green" {
  source              = "./Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-s-g"
  port                = 80
  protocol            = "HTTP"
  vpc                 = module.vpc.aws_vpc
  tg_type             = "ip"
  health_check_path   = "/status"
  health_check_port   = var.port_app_server
}

# ------- Creating Target Group for the client ALB blue environment -------
module "target_group_client_blue" {
  source              = "./Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-c-b"
  port                = 80
  protocol            = "HTTP"
  vpc                 = module.vpc.aws_vpc
  tg_type             = "ip"
  health_check_path   = "/"
  health_check_port   = var.port_app_client
}

# ------- Creating Target Group for the client ALB green environment -------
module "target_group_client_green" {
  source              = "./Modules/ALB"
  create_target_group = true
  name                = "tg-${var.environment_name}-c-g"
  port                = 80
  protocol            = "HTTP"
  vpc                 = module.vpc.aws_vpc
  tg_type             = "ip"
  health_check_path   = "/"
  health_check_port   = var.port_app_client
}

# ------- Creating Security Group for the server ALB -------
module "security_group_alb_server" {
  source              = "./Modules/SecurityGroup"
  name                = "alb-${var.environment_name}-server"
  description         = "Controls access to the server ALB"
  vpc_id              = module.vpc.aws_vpc
  cidr_blocks_ingress = ["0.0.0.0/0"]
  ingress_port        = 80
}

# ------- Creating Security Group for the client ALB -------
module "security_group_alb_client" {
  source              = "./Modules/SecurityGroup"
  name                = "alb-${var.environment_name}-client"
  description         = "Controls access to the client ALB"
  vpc_id              = module.vpc.aws_vpc
  cidr_blocks_ingress = ["0.0.0.0/0"]
  ingress_port        = 80
}

# ------- Creating Server Application ALB -------
module "alb_server" {
  source         = "./Modules/ALB"
  create_alb     = true
  name           = "${var.environment_name}-ser"
  subnets        = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_group = module.security_group_alb_server.sg_id
  target_group   = module.target_group_server_blue.arn_tg
}

# ------- Creating Client Application ALB -------
module "alb_client" {
  source         = "./Modules/ALB"
  create_alb     = true
  name           = "${var.environment_name}-cli"
  subnets        = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_group = module.security_group_alb_client.sg_id
  target_group   = module.target_group_client_blue.arn_tg
}

# ------- ECS Role -------
module "ecs_role" {
  source             = "./Modules/IAM"
  create_ecs_role    = true
  name               = var.iam_role_name["ecs"]
  name_ecs_task_role = var.iam_role_name["ecs_task_role"]
  dynamodb_table     = [module.dynamodb_table.dynamodb_table_arn]
  ssm_parameter_arns = [module.ssm_parameter.ssm_parameter_arn, module.ssm_parameter_alb.ssm_parameter_arn]
}

# ------- Creating a IAM Policy for role -------
module "ecs_role_policy" {
  source        = "./Modules/IAM"
  name          = "ecs-ecr-${var.environment_name}"
  create_policy = true
  attach_to     = module.ecs_role.name_role
}

# ------- Creating client ECR Repository to store Docker Images -------
module "ecr" {
  source = "./Modules/ECR"
  name   = "demo"
}

# ------- Creating ECS Task Definition for the server -------
module "ecs_taks_definition_server" {
  source             = "./Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-server"
  container_name     = var.container_name["server"]
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  cpu                = 256
  memory             = "512"
  container_port     = var.port_app_server
  container_cpu      = "256"  
  container_memory   = "512"    
  docker_image_url   = "${module.ecr.ecr_repository_url}:back"
  aws_region         = var.aws_region
  secrets   = [
    {
      name = module.ssm_parameter.parameter_name,
      arn  = module.ssm_parameter.ssm_parameter_arn
    },
    {
      name = module.ssm_parameter_alb.parameter_name,
      arn  = module.ssm_parameter_alb.ssm_parameter_arn
    }
]
}

# ------- Creating ECS Task Definition for the client -------
module "ecs_taks_definition_client" {
  source             = "./Modules/ECS/TaskDefinition"
  name               = "${var.environment_name}-client"
  container_name     = var.container_name["client"]
  execution_role_arn = module.ecs_role.arn_role
  task_role_arn      = module.ecs_role.arn_role_ecs_task_role
  cpu                = 256
  memory             = "512"
  container_port     = var.port_app_client
  container_cpu      = "256"  
  container_memory   = "512"    
  docker_image_url   = "${module.ecr.ecr_repository_url}:front"
  aws_region         = var.aws_region
}

# ------- Creating a server Security Group for ECS TASKS -------
module "security_group_ecs_task_server" {
  source          = "./Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-server"
  description     = "Controls access to the server ECS task"
  vpc_id          = module.vpc.aws_vpc
  ingress_port    = var.port_app_server
  security_groups = [module.security_group_alb_server.sg_id]
}
# ------- Creating a client Security Group for ECS TASKS -------
module "security_group_ecs_task_client" {
  source          = "./Modules/SecurityGroup"
  name            = "ecs-task-${var.environment_name}-client"
  description     = "Controls access to the client ECS task"
  vpc_id          = module.vpc.aws_vpc
  ingress_port    = var.port_app_client
  security_groups = [module.security_group_alb_client.sg_id]
}

# ------- Creating ECS Cluster -------
module "ecs_cluster" {
  source = "./Modules/ECS/Cluster"
  name   = var.environment_name
}

# ------- Creating ECS Service server -------
module "ecs_service_server" {
  depends_on          = [module.alb_server]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-server"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id
  arn_task_definition = module.ecs_taks_definition_server.arn_task_definition  
  security_group_ids  = [module.security_group_ecs_task_server.sg_id] 
  subnet_ids          = [module.vpc.private_subnets_server[0], module.vpc.private_subnets_server[1]]
  target_group_arn    = module.target_group_server_blue.arn_tg
  desired_tasks       = 1
  container_port      = var.port_app_server
  container_memory    = "512"
  container_cpu       = 256
  execution_role_arn  = module.ecs_role.arn_role
  task_role_arn       = module.ecs_role.arn_role_ecs_task_role 
  docker_image_url    = module.ecr.ecr_repository_url 
  cpu                 = "256" 
  memory              = "512" 
  container_name      = var.container_name["server"] 
  aws_region          = var.aws_region 
}

# ------- Creating ECS Service client -------
module "ecs_service_client" {
  depends_on          = [module.alb_client]
  source              = "./Modules/ECS/Service"
  name                = "${var.environment_name}-client"
  ecs_cluster_id      = module.ecs_cluster.ecs_cluster_id 
  arn_task_definition = module.ecs_taks_definition_client.arn_task_definition
  security_group_ids  = [module.security_group_ecs_task_client.sg_id]
  subnet_ids          = [module.vpc.private_subnets_client[0], module.vpc.private_subnets_client[1]]
  target_group_arn    = module.target_group_client_blue.arn_tg
  desired_tasks       = 1
  container_port      = var.port_app_client
  container_memory    = "512"
  container_cpu       = 256
  execution_role_arn  = module.ecs_role.arn_role
  task_role_arn       = module.ecs_role.arn_role_ecs_task_role 
  docker_image_url    = module.ecr.ecr_repository_url
  cpu                 = "256" 
  memory              = "512" 
  container_name      = var.container_name["client"] 
  aws_region          = var.aws_region 
}


module "ssm_parameter" {
  source  = "./Modules/SSM"
  name    = "DYNAMODB_TABLE"
  value   = "assets-table-demo"
  type    = "String" 
}

module "ssm_parameter_alb" {
  source  = "./Modules/SSM"
  name    = "LOAD_BALANCER_URL"
  value   =  module.alb_server.dns_alb
  type    = "String" 
}
# ------- Creating ECS Autoscaling policies for the server application -------
module "ecs_autoscaling_server" {
  depends_on   = [module.ecs_service_server]
  source       = "./Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-server"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- Creating ECS Autoscaling policies for the client application -------
module "ecs_autoscaling_client" {
  depends_on   = [module.ecs_service_client]
  source       = "./Modules/ECS/Autoscaling"
  name         = "${var.environment_name}-client"
  cluster_name = module.ecs_cluster.ecs_cluster_name
  min_capacity = 1
  max_capacity = 4
}

# ------- Creating a SNS topic -------
module "sns" {
  source   = "./Modules/SNS"
  sns_name = "sns-${var.environment_name}"
}


# ------- Creating Bucket to store assets accessed by the Back-end -------
module "s3_assets" {
  source      = "./Modules/S3"
  bucket_name = "assets-${var.aws_region}-${random_id.RANDOM_ID.hex}"
}

# ------- Creating Dynamodb table by the Back-end -------
module "dynamodb_table" {
  source = "./Modules/Dynamodb"
  name   = "assets-table-${var.environment_name}"
}
=======
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Define Public Subnets
resource "aws_subnet" "public_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1a"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1b"
  }
}

# Define Private Subnets
resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-1a"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-1b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gw"
  }
}

# NAT Gateways
resource "aws_eip" "nat_eip1" {
  vpc = true
  tags = {
    Name = "nat-eip-1a"
  }
}

resource "aws_nat_gateway" "nat_gw1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.public_subnet1.id
  tags = {
    Name = "nat-gw-1a"
  }
}

resource "aws_eip" "nat_eip2" {
  vpc = true
  tags = {
    Name = "nat-eip-1b"
  }
}

resource "aws_nat_gateway" "nat_gw2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.public_subnet2.id
  tags = {
    Name = "nat-gw-1b"
  }
}

# Route Tables and Associations
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rta1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id
  }
  tags = {
    Name = "private-rt-1a"
  }
}

resource "aws_route_table_association" "private_rta1" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table" "private_rt2" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id
  }
  tags = {
    Name = "private-rt-1b"
  }
}

resource "aws_route_table_association" "private_rta2" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_rt2.id
}

resource "aws_ecr_repository" "my_repository" {
  name                 = "my-ecr-repository"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name   = "ecs_task_execution_role_policy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security group for ALB"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["<Your-Subnet-ID>", "<Another-Subnet-ID>"]
}

resource "aws_lb_target_group" "tg_80" {
  name     = "tg-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "aws_vpc.main.id"
}

resource "aws_lb_target_group" "tg_3001" {
  name     = "tg-3001"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = "aws_vpc.main.id"
}

resource "aws_lb_listener" "listener_80" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_80.arn
  }
}

resource "aws_lb_listener" "listener_3001" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 3001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_3001.arn
  }
}

# Update the ECS Services to include load balancer configuration
resource "aws_ecs_service" "my_service_80" {
  name            = "my-service-80"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_80.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_80.arn
    container_name   = "my-container-80"
    container_port   = 80
  }
}

resource "aws_ecs_service" "my_service_3001" {
  name            = "my-service-3001"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_3001.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_3001.arn
    container_name   = "my-container-3001"
    container_port   = 3001
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs_tasks_sg"
  description = "Allow inbound access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_task_definition" "my_task_80" {
  family                   = "my-task-family-80"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-container-80"
      image     = "${aws_ecr_repository.my_repository.repository_url}:latest"
      essential = true
      memory    = 512
      cpu       = 256
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        },
      ]
    }
  ])
}

# Task definition for the service running on port 3001
resource "aws_ecs_task_definition" "my_task_3001" {
  family                   = "my-task-family-3001"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-container-3001"
      image     = "${aws_ecr_repository.my_repository.repository_url}:latest" # Assuming the same image for simplicity
      essential = true
      memory    = 512
      cpu       = 256
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 3001
          protocol      = "tcp"
        },
      ]
    }
  ])
}
>>>>>>> 5ae597e87db95acfb790004de8cc689bc2f158ea

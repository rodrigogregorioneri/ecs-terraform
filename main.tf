resource "aws_ecs_cluster" "observability_cluster_fargate" {
  name = "observability-cluster-fargate"
}

resource "aws_ecs_task_definition" "observability_task_definition" {
  family                   = "observability-task-fargate"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "observability",
      image     = "amazon/amazon-ecs-sample",
      essential = true,
      portMappings = [
        {
          containerPort = 80,
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "observability_servico_fargate" {
  name            = "observability-servico-fargate"
  cluster         = aws_ecs_cluster.observability_cluster_fargate.id
  task_definition = aws_ecs_task_definition.observability_task_definition.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    assign_public_ip = true
    security_groups = [aws_security_group.meu_grupo_de_seguranca.id]
  }

  desired_count = 1
}


resource "aws_security_group" "meu_grupo_de_seguranca" {
  name        = "grupodesegurancaecs"
  description = "Security Group para o servico ECS Fargate"
  vpc_id      = aws_vpc.observability_vpc.id # Substitua pelo ID do seu VPC

  # Regra de entrada: Permitir tráfego HTTP (porta 80) de qualquer lugar
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regra de saída: Permitir todo o tráfego de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "meu-grupo-de-seguranca-ecs"
  }
}
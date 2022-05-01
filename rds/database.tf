#Create an PostgreSql RDS
resource "aws_db_subnet_group" "default" {
  name        = "${var.name}-${var.environment}-subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = [ var.private_subnets[0].id, var.private_subnets[1].id ]
}

data "aws_secretsmanager_secret_version" "creds" {
  # Fill in the arn you gave to your secret
  secret_id = var.secret_manager_arn
}

locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.creds.secret_string
  )
}

resource "aws_db_instance" "postgresql" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "12.7"
  instance_class       = var.db_instance_type
  db_name              = local.db_creds.app_db_name
  username             = local.db_creds.master_user
  password             = local.db_creds.master_password
  multi_az             = "false"
  db_subnet_group_name      = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible = "false"
  apply_immediately = "true"
  identifier = "${var.name}-${var.environment}-rds"
  skip_final_snapshot = "true"
  parameter_group_name = "default.postgres12"
}

#Create RDS Security Group
resource "aws_security_group" "rds_sg" {
  depends_on = [var.ec2_sg_group]
  vpc_id      = var.vpc
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [var.ec2_sg_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "RDS-Endpoint" {
  value = aws_db_instance.postgresql.address
}

output "rds" {
  value = aws_db_instance.postgresql
}

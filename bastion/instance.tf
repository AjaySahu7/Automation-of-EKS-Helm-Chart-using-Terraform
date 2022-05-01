data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]

  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

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

#Create an Instance

resource "aws_instance" "ec2_instance" {
  ami             =  data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg_group.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data       = templatefile("${path.module}/node.sh", 
  { 
    region              = var.aws_region, 
    master_user         = local.db_creds.master_user, 
    master_pass         = local.db_creds.master_password,
    app_db_name         = local.db_creds.app_db_name,
    app_db_username     = local.db_creds.app_db_username,
    app_db_password     = local.db_creds.app_db_password,
    banking_db_name     = local.db_creds.banking_db_name,
    banking_db_username = local.db_creds.banking_db_username,
    banking_db_password = local.db_creds.banking_db_password,
    host                = var.RDS-Endpoint
  }
  )

  tags = {
    Name = "${var.name}-${var.environment}-bastion"
  }
  root_block_device {
    volume_size = 10
  }
  depends_on = [var.rds]

  connection {
    type = "ssh"
    host = aws_instance.ec2_instance.public_ip
    user = "ubuntu"
    private_key = file("${path.module}/${var.key_name}.pem")
  }

  provisioner "remote-exec" {
     inline = [
      "mkdir /home/ubuntu/secret"
    ]
  }
 
  provisioner "file" {
    source      = "${path.module}/app-backend-helm"
    destination = "/home/ubuntu/app-backend-helm"
  }
  
  provisioner "file" {
    source      = "${path.module}/app-frontend-helm"
    destination = "/home/ubuntu/app-frontend-helm"
  }

  provisioner "file" {
    source      = "${path.module}/hybrid-api"
    destination = "/home/ubuntu/hybrid-api"
  }

  provisioner "file" {
    source      = "${path.module}/docs-hybrid"
    destination = "/home/ubuntu/docs-hybrid"
  }

  provisioner "file" {
    source      = "${path.module}/grafana-helm-chart"
    destination = "/home/ubuntu/grafana-helm-chart"
  }

  provisioner "file" {
    content = templatefile("${path.module}/app-backend-css.tpl",{
      app_namespace        = var.app_namespace
      region               = var.aws_region
      app-service-account  = var.app-service-account
    })
    destination = "/home/ubuntu/secret/app-backend-css.yaml"
  } 

  provisioner "file" {
    content = templatefile("${path.module}/app-backend-ex-secret.tpl",{
      app_namespace = var.app_namespace
    })
    destination = "/home/ubuntu/secret/app-backend-ex-secret.yaml"
  } 

  provisioner "file" {
    content = templatefile("${path.module}/api-hybrid-external-secret.tpl",{
      bank_namespace = var.bank_namespace
    })
    destination = "/home/ubuntu/secret/api-hybrid-external-secret.yaml"
  } 

  provisioner "file" {
    content = templatefile("${path.module}/api-hybrid-css.tpl",{
      bank_namespace        = var.bank_namespace
      region                = var.aws_region
      bank-service-account  = var.bank-service-account
    })
    destination = "/home/ubuntu/secret/api-hybrid-css.yaml"
  } 

  provisioner "file" {
    content = templatefile("${path.module}/docs-hybrid-external-secret.tpl",{
      bank_namespace = var.bank_namespace
    })
    destination = "/home/ubuntu/secret/docs-hybrid-external-secret.yaml"
  } 

  provisioner "file" {
    content = templatefile("${path.module}/app-frontend-ex-secret.tpl",{
      app_namespace = var.app_namespace
    })
    destination = "/home/ubuntu/secret/app-frontend-ex-secret.yaml"
  } 

  provisioner "file" {
    source      = "${path.module}/script.sh"
    destination = "/home/ubuntu/script.sh"
  }

  provisioner "file" {
    source      = "${path.module}/app.sh"
    destination = "/home/ubuntu/app.sh"
  }

  provisioner "file" {
    source      = "${path.module}/bank.sh"
    destination = "/home/ubuntu/bank.sh"
  }

  provisioner "file" {
    source      = "${path.module}/fluentd-config-map.yaml"
    destination = "/home/ubuntu/fluentd-config-map.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/fluentd-dapr-with-rbac.yaml"
    destination = "/home/ubuntu/fluentd-dapr-with-rbac.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/migrate.yaml"
    destination = "/home/ubuntu/migrate.yaml"
  }
  
  provisioner "file" {
    source      = "${path.module}/elk-ingress.yaml"
    destination = "/home/ubuntu/elk-ingress.yaml"
  }

  provisioner "remote-exec" {
     inline = [
      "chmod +x app.sh",
      "chmod +x bank.sh",
      "chmod +x script.sh"
    ]
  }
}

#Create Instance Security Group
resource "aws_security_group" "ec2_sg_group" {
  description = "Bastion Host"
  name_prefix = "${var.name}-${var.environment}-bastion-"
  vpc_id      = var.vpc

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-${var.environment}-bastion_sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "ec2_sg_group" {
  value = aws_security_group.ec2_sg_group
}

output "private_ip" {
  value = aws_instance.ec2_instance.private_ip
}
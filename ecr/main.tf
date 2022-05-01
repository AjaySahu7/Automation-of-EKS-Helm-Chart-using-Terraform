#ECR repository
resource "aws_ecr_repository" "ecr" {
  count = length(var.ecr_name)
  name                 = element(var.ecr_name, count.index)
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#Manages an ECR repository lifecycle policy.
resource "aws_ecr_lifecycle_policy" "ecrpolicy" {
  count = length(var.ecr_name)
  repository = element(var.ecr_name, count.index)

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 4 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 4
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
 depends_on = [aws_ecr_repository.ecr]
}

#resource "null_resource" "push_docker_image" {
#   count = length(var.ecr_name)
#
#    triggers = {
#       shell_hash = "${sha256(file("${path.module}/initial_script.sh"))}"
#    }
#   provisioner "local-exec" {
#    
#    command = "/bin/bash initial_script.sh"
#    working_dir = "${path.module}"
#    environment = {
#      AWS_DEFAULT_REGION = var.region
#      ecr_name = element(var.ecr_name, count.index)
#      repository = element(var.repository, count.index)
#      account_id = var.account_id
#    }
#  }
#  depends_on = [aws_ecr_repository.ecr]
#}
#
#output "docker_image" {
#  value       = null_resource.push_docker_image
#}


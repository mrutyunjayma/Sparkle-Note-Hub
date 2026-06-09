resource "aws_ecr_repository" "repos" {
  count = length(var.repositories)

  name = var.repositories[count.index]

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = false
  }

  image_tag_mutability = "MUTABLE"
}
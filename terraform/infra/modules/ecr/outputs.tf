output "repo_urls" {
  value = aws_ecr_repository.repos[*].repository_url
}
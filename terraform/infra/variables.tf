variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "project_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-south-1"   
}

variable "azs" {
  type = list(string)
}

variable "repositories" {
  type = list(string)
}
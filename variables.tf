variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "availability_zones" {
    type = list(string)
    description = "AWS availability zones for the VPC"
    default = ["us-east-1a", "us-east-1b"]
}
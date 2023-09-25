variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-1"
}

variable "availability_zones" {
    type = list(string)
    description = "AWS availability zones for the VPC"
    default = ["us-west-1a", "us-west-1b"]
}
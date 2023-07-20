variable "app-name" {
  type = string
  default = "tf-web-app"
  description = "The name of the application"
}

variable "region" {
  type = string
  default = "us-east-2"
  description = "Region where the resources will be created"
}

variable "num-replicas" {
  type = number
  default = 2
  description = "Number of replicas to create. This impacts how many instances and how many subnets are created"
  validation {
    condition = var.num-replicas ==2 || var.num-replicas ==3
    error_message = "Number of replicas must be 2 or 3"
  }
}

variable "associate_public_ip" {
  type = bool
  default = false
  description = "Associate public IP addresses with web app the instances? Default is false"
}
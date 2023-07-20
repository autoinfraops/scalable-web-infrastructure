resource "aws_vpc" "app-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.app-name}-vpc"
  }
}

# This data source is used to get the AZs in the region
data "aws_availability_zones" "example" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}


resource "aws_subnet" "app-subnets" {
  count      = var.num-replicas
  vpc_id     = aws_vpc.app-vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24"

  # the following line will only work if count is less than 3
  # this is only needed to force subnets to specific AZs
  # otherwise, aws will distribute them across all AZs automatically

  # Sometimes the AWS tenant creates subnets in the same AZ
  # Uncomment the line below to overcome the issue

  availability_zone = data.aws_availability_zones.example.names[count.index]

  tags = {
    Name = "${var.app-name}-${count.index + 1}-subnet"
  }
}

# SG used with instances to allow inbound traffic
resource "aws_security_group" "instances" {
  name   = "instance-security-group"
  vpc_id = aws_vpc.app-vpc.id
}

# security group rule to allow ingress traffic on port 8080
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id

  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"

  #allowing all ip addressess
  cidr_blocks = ["0.0.0.0/0"]
}

# Optional - security group rule to allow ingress traffic on port 22
# resource "aws_security_group_rule" "allow_ssh_inbound" {
#   type              = "ingress"
#   security_group_id = aws_security_group.instances.id

#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"

#   #allowing all ip addressess
#   cidr_blocks = ["0.0.0.0/0"]
# }

# Optional - if you want your instances to access the internet:
# resource "aws_security_group_rule" "allow_http_outbound" {
#   type              = "egress"
#   security_group_id = aws_security_group.instances.id

#   from_port   = -1
#   to_port     = -1
#   protocol    = "all"

#   #allowing all ip addressess
#     cidr_blocks = ["0.0.0.0/0"]
# }

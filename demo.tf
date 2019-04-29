variable "region" {
  default = "ca-central-1"
}

variable "ami" {
  default = "ami-0a851426a8a56bf4b"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "tf_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.tf_network.id}"
}

resource "aws_subnet" "subnet_subnet_a" {
  vpc_id                  = "${aws_vpc.tf_network.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.gateway"]
}

resource "aws_subnet" "subnet_subnet_b" {
  vpc_id                  = "${aws_vpc.tf_network.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.gateway"]
}

resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.tf_network.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway.id}"
  }
}

resource "aws_route_table_association" "public_route_assoc_a" {
  subnet_id      = "${aws_subnet.subnet_subnet_a.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}
resource "aws_route_table_association" "public_route_assoc_b" {
  subnet_id      = "${aws_subnet.subnet_subnet_b.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_key_pair" "edgenda_key_demo2" {
  key_name   = "ec2_instance_key_demo2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCxnuSEUXTrKDxC61sqrP8zil1XVR8VIDqw8M/qAQqWT0KIFIPCrm3jY4EoqNpeeiooUsF2yQjttYpG3EFlVEoh9PcoI3gJH9S5fuqCy3tEA8WY868fHHlnz1URufsvUGD9Bj8lISxQdTYVFQaRKqWpQDI5rHBLqVKRkRe3nlem+ZcI/eFyXQ9GrqSS8e0k5d54F5b2xMsWqwoyoJstDTStrlf4TwjWoFudn7S9339DR1ZQoyJr950L83ojCsl57D4nG0htKUAmivY0wSI+RR+vhKkiAtco1qlgqp3ZX+Es5EkuWkOGEz2qwXo4RY3d/aHFk8pRViG9BxE+wanSBAje+LN/1PGzsacOOxmjYcsF3/kgf481WlAZay0FUgEDriBl156ixmOzMaq8D6lV6bUkl1W/s40y5D5IYrDtRIzmdhQJIqGW/Y/Wxzm7fXU+e2wsgr51J0sXW5Yee1ZpuKFBch3r81aaINUyEIIDLvILrSKv6Ot28gnnD/4oDe3bD8IDNS5K5D9wClzpAE/8nUZBfT8P7zq23Awc5yIexfG+ApoP8FcuqU4rsMYNB2wwh4NP7d/Ec5nvHTeRvr90QGEomEEnvzCLQrCAA78+fB7GZyf1zZICD5GzTalgAQBfGD4zfxh3hwPrtE1OQI+OwFMrYQRjxp+m6sXR7K1OEvprQ== efog@STRONGBAD10"
}

resource "aws_security_group" "default_security_group_ipv4" {
  vpc_id = "${aws_vpc.tf_network.id}"
  name   = "Ensure_SSH_Allow_All_IPV4"

  ingress {
    to_port     = 22
    from_port   = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "micro_vm" {
  ami           = "${var.ami}"
  key_name      = "${aws_key_pair.edgenda_key_demo2.key_name}"
  instance_type = "t2.micro"

  subnet_id                   = "${aws_subnet.subnet_subnet_a.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    "${aws_security_group.default_security_group_ipv4.id}"]
}

# resource "aws_eip" "ip" {
#   instance                  = "${aws_instance.micro_vm.id}"
#   vpc                       = true
#   associate_with_private_ip = "${aws_instance.micro_vm.private_ip}"
#   depends_on                = ["aws_internet_gateway.gateway"]
# }

output "ip" {
  value = "${aws_instance.micro_vm.public_ip}"
}

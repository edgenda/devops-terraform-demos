variable "region" {
  default = "ca-central-1"
}

variable "ami" {
  default = "ami-0a851426a8a56bf4b"
}

provider "aws" {
  region = "${var.region}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_vpc" "tf_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.tf_network.id}"
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = "${aws_vpc.tf_network.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  depends_on              = ["aws_internet_gateway.gateway"]
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = "${aws_vpc.tf_network.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}b"
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
  subnet_id      = "${aws_subnet.subnet_a.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_route_table_association" "public_route_assoc_b" {
  subnet_id      = "${aws_subnet.subnet_b.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_key_pair" "edgenda_key" {
  key_name   = "ec2_instance_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+oJWsl5iLfdgp9dWsmFNENGwWGdg1/z6ES7Z29EiG0dfeCb9RlY5CaSzKCIS0DB6FIYIGdA6xFWWDMl+UUiXBMeQMOBGmKX5vfBujwgsOO2xMC/Y64Ruv1tI/sVd43I3ejckXWxxqphe4efOV7tVgwN8pI2+X5ECWRoODH13juOS9uI3bNlIHlc+bqLsfrQsOjU68xDkanz5CtjIvEUgsHlUC4rRZu0I34+OKaA4xjwJ54ejowRNKLqItYm9f3FQxnhNXZ3FZ4c45/Aghirev9grPC4T1CfCAqF/xm/cHO51yaR9ries+Z76jNVkQHcEScdqxxEReEMuT3dAWg5d2dGM4E0Pg5SyiSbXC+n6JBnKxxNncxgw1Txe1rLW+2zXm0pucK4uJKhpNUkuqoHnRxC+8P68nVsIMF0PGjob3E1AREfHuPate3fOhBBBrOjpvXByp5qdoXqm15IfRCCv5OwrQxxCwmkQdXkQxqBUu/OzWduqDTP0tHrm3AoNghs+DOI8hq199Lucrcn8Zn9rBSlr3qdcxfHakxqGAy70H49pkQr3yG9agh9CVGQdFHBzp264oj1+c5MWNJ2mjZPQoKyPzM1aBrx/EJlEb6HdJpMHrzU7JFL7fYYLOX+XYHuq0xV73pnBUQIVm/kLUvMHFB/vC2yFm63Emem3IHkU7kQ== efog@STRONGBAD10"
}

resource "aws_security_group" "ensure_ssh_ipv4" {
  vpc_id = "${aws_vpc.tf_network.id}"
  name   = "Ensure_SSH_Allow_All_IPV4"

  ingress {
    to_port     = 22
    from_port   = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_http" {
  vpc_id = "${aws_vpc.tf_network.id}"
  name   = "allow_http"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_https" {
  vpc_id = "${aws_vpc.tf_network.id}"
  name   = "allow_https"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_out_ipv4" {
  vpc_id = "${aws_vpc.tf_network.id}"
  name   = "Allow_All_Out_IPV4"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webservers" {
  ami           = "${data.aws_ami.ubuntu.id}"
  key_name      = "${aws_key_pair.edgenda_key.key_name}"
  instance_type = "t2.micro"
  count         = 2

  subnet_id                   = "${count.index % 2 == 0 ? aws_subnet.subnet_a.id : aws_subnet.subnet_b.id}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.ensure_ssh_ipv4.id}",
    "${aws_security_group.allow_all_out_ipv4.id}",
    "${aws_security_group.allow_http.id}",
    "${aws_security_group.allow_https.id}",
  ]

  provisioner "remote-exec" {
    connection {
      user        = "ubuntu"
      private_key = "${file("~/.ssh/awstfdemo")}"
    }

    inline = [
      "sudo apt install -y python",
    ]
  }
}

resource "aws_elb" "lb" {
  name            = "terraform-demo-elb"
  instances       = ["${aws_instance.webservers.*.id}"]
  security_groups = ["${aws_security_group.allow_http.id}", "${aws_security_group.allow_https.id}", "${aws_security_group.allow_all_out_ipv4.id}", "${aws_security_group.ensure_ssh_ipv4.id}"]
  subnets         = ["${aws_subnet.subnet_a.id}", "${aws_subnet.subnet_b.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "ansible_host" "default" {
  count              = "${aws_instance.webservers.count}"
  inventory_hostname = "${aws_instance.webservers.*.id[count.index]}"

  vars {
    ansible_user = "ubuntu"
    ansible_host = "${aws_instance.webservers.*.public_ip[count.index]}"
  }
}

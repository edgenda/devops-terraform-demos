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

resource "aws_subnet" "subnet_a" {
  vpc_id                  = "${aws_vpc.tf_network.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.gateway"]
}

resource "aws_subnet" "subnet_b" {
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

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = "${aws_subnet.subnet_a.id}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

resource "aws_key_pair" "edgenda_key" {
  key_name   = "ec2_instance_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB+DbV+bzONPPcIDl9iyMVgd0B553nL4qiDnvYBXft8JCDquyA4Xci8mhKRCh/CXgu/HU0ndB0gwqnS1CCK5vMD56yGq9kN9ZKaCZjpgwb2D2d1+geMWlfTbG3c5+8EOHHrGsIxcunEhutpQrQHq++4RCnBfXiEkbKuzayYLxxU+nCIDbxBteTn9Z47xvHmeh1M/pjD94BzNMiPvazOs5JbP2jTiCpiFpVoBK1wxKPb2VaKj8vKcQ0bztggc+t+LAA8yalh6uSqeGE7Pvw2jmaD/2LO3UMOaDYn3CogKLGFoI7zMUOXBr5oFUvo6s+SyyCOI9QkrDFCIKku8DNCaj+Sg/YqUDoUSixidCVlRdayAhyUpQeTvuORNTIhcSCgZyqJPNg6Ja8w6SeO6Tf2qrbqsjYWNBrFVKHqd8nFg1M2WDQBlLlEgI5xDsmYIn+tKLtTSiU+da/jbr0MNu0EINAoP5jcfte+9BGJGQ4/W0y0Gp2LL5Pj4aNJrSsXRlx1YL1I3P416pHpI7qUuLDnjVhBIZWhTl9g8lDOpZh41W1By9WHs9S5lduHL1CyG36HewbY1hrzcbH+p0pMtvLSFkToIvMVTzMveFm4cvw5fbsNyjRX7umXGg33qkie2fQjgdT7Tt10p49R1YbKyT6k6Tz368BFI2j2qnTWmqf98iJ0w== efog@STRONGBAD10"
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
  ami           = "${var.ami}"
  key_name      = "${aws_key_pair.edgenda_key.key_name}"
  instance_type = "t2.micro"
  count         = 2

  subnet_id                   = "${aws_subnet.subnet_a.id}"
  associate_public_ip_address = "true"

  vpc_security_group_ids = [
    "${aws_security_group.ensure_ssh_ipv4.id}",
    "${aws_security_group.allow_all_out_ipv4.id}",
  ]
}

resource "aws_elb" "lb" {
  name               = "terraform-demo-elb"
  instances          = ["${aws_instance.webservers.*.id}"]
  security_groups    = ["${aws_security_group.allow_http.id}", "${aws_security_group.allow_https.id}"]
  subnets            = ["${aws_subnet.subnet_a.id}"]

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
}

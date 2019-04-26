variable "region" {
  default = "ca-central-1"
}

variable "ami" {
  default = "ami-0a851426a8a56bf4b"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "edgenda_key" {
  key_name   = "ec2_instance_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDB+DbV+bzONPPcIDl9iyMVgd0B553nL4qiDnvYBXft8JCDquyA4Xci8mhKRCh/CXgu/HU0ndB0gwqnS1CCK5vMD56yGq9kN9ZKaCZjpgwb2D2d1+geMWlfTbG3c5+8EOHHrGsIxcunEhutpQrQHq++4RCnBfXiEkbKuzayYLxxU+nCIDbxBteTn9Z47xvHmeh1M/pjD94BzNMiPvazOs5JbP2jTiCpiFpVoBK1wxKPb2VaKj8vKcQ0bztggc+t+LAA8yalh6uSqeGE7Pvw2jmaD/2LO3UMOaDYn3CogKLGFoI7zMUOXBr5oFUvo6s+SyyCOI9QkrDFCIKku8DNCaj+Sg/YqUDoUSixidCVlRdayAhyUpQeTvuORNTIhcSCgZyqJPNg6Ja8w6SeO6Tf2qrbqsjYWNBrFVKHqd8nFg1M2WDQBlLlEgI5xDsmYIn+tKLtTSiU+da/jbr0MNu0EINAoP5jcfte+9BGJGQ4/W0y0Gp2LL5Pj4aNJrSsXRlx1YL1I3P416pHpI7qUuLDnjVhBIZWhTl9g8lDOpZh41W1By9WHs9S5lduHL1CyG36HewbY1hrzcbH+p0pMtvLSFkToIvMVTzMveFm4cvw5fbsNyjRX7umXGg33qkie2fQjgdT7Tt10p49R1YbKyT6k6Tz368BFI2j2qnTWmqf98iJ0w== efog@STRONGBAD10"
}

resource "aws_security_group" "default_security_group_ipv4" {
  name = "Ensure_SSH_Allow_All_IPV4"

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
  key_name      = "${aws_key_pair.edgenda_key.key_name}"
  instance_type = "t2.micro"

  security_groups = ["${aws_security_group.default_security_group_ipv4.name}"]
}

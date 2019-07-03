terraform {
  backend "s3" {
    bucket = "edgenda-devops-lab13-student00"
    key    = "labbnc13vm0"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

module "lab3" {
    source = "./mymodule"
}

output "elb_dns" {
  value = "${module.lab3.elb_dns}"
}

output "instances_ip" {
  value = "${module.lab3.instances_ip}"
}
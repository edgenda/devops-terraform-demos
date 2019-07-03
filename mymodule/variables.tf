variable "region" {
  default = "us-east-1"
}

variable "ami" {
  default = "ami-0a851426a8a56bf4b"
}

variable "authorized_key" {
  type = "map"
  default = {
    public = "demo_key.pub"
    private = "./demo_key"
  }
}

variable "instances_count" {
  default = "2"
}

variable "instances_type" {
  default = "t2.micro"
}

variable "tags" {
  type = "map"
  default = {
    app = "NGINX"
    env = "dev"
  }
}
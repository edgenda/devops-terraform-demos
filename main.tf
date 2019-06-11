module "lab4" {
    source = "./modules/lab"
    region = "eu-central-1"
}

output "public_dns" {

    value = "${module.lab4.public_dns}"
}


module "lab4" {
    source = "./modules/lab"
    region = "eu-central-1"
}

output "vms_public_dns" {
    value = "${module.lab4.vms_public_dns}"
}
output "elb_public_dns" {
    value = "${module.lab4.elb_public_dns}"
}



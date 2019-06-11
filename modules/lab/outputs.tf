output "vms_public_dns" {
    value = "${aws_instance.webservers.*.public_dns}"
}

output "elb_public_dns" {
    value = "${aws_elb.lb.dns_name}"
}

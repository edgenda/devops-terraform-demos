output "pubilc_dns" {
    value = "${aws_instance.webservers.*.public_dns}"
}
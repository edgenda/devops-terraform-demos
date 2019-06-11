output "pubilc_dns" {
    value = "${aws_instance.webserver.*.pubilc_dns}"
}
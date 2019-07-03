
output "elb_dns" {
  value = "${aws_elb.lb.dns_name}"
}

output "instances_ip" {
  value = "${aws_instance.webservers.*.public_ip}"
}

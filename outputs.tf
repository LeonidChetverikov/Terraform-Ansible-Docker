
output "ip" {
  value      = "${aws_instance.DR_ec2.*.public_ip}"
}

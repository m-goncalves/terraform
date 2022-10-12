output "dev_instance_ip" {
  value = aws_instance.dev_instance.public_ip
}

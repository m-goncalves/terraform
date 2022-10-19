output "asg_name" {
  value       = aws_autoscaling_group.cluster_webservers_asg.name
  description = "The name of the Auto Scaling Group"
}

output "alb_dns_name" {
  value = aws_lb.cluster_webservers_lb.dns_name
  description = "The domain name of the load balancer"
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
  description = "The ID of the security group attached to the load balancer"
}
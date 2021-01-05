# A way to expose information to the user.
output "alb_dns_name" {
    value = aws_lb.test-loadbalancer.dns_name
    description = "The domain name of the load balancer."
}

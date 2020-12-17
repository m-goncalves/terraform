provider "aws" {
    region = "us-east-2"
}

# To spin up an auto scaling group an "aws_launch_configuration" is needed. 
# This ALC requires an "image_id" as well as a "security_group".
resource "aws_launch_configuration" "test-auto-scaling" {
    image_id        = "ami-0c55b159cbfafe1f0"
    instance_type   = "t2.micro"
    #Instructs the ec2 instance to use the security group. 
    security_groups= [aws_security_group.test-security-group.id]
    
    user_data = <<-EOF
                #!/bin/bash
                echo "hello, World!"> index.html
                nohub busybox test-httpd -f -p ${var.server_port} &
                EOF
    # Makes sure that a replacement for a specific resource will be created before 
    # this resource gets deleted. 
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "test-auto-scaling" {
    launch_configuration    = aws_launch_configuration.test-auto-scaling.name
    vpc_zone_identifier     = data.aws_subnet_ids.default.ids
    # It tells the target-group which instances to send requests to.
    target_group_arns       = [aws_lb_target_group.test-target-group.arn]
    health_check_type       = "ELB"
    min_size                = 2
    max_size                = 3
    tag {
        key                 = "Name"
        value               = "test-asg"
        propagate_at_launch = true
    }
  
}

# An auto scaling group needs to know in which VPC subnets the EC2
# instances will to be deployed. The bellow resources act like filters.
data "aws_vpc" "default" {
    default = true
  
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id 
  
}
# A security group is required to allow incoming traffic
resource "aws_security_group" "test-security-group" {
    name = "general-security-group"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        #cidr_blocks allow to specify IP adress ranges
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# A loadbalancer is required since the system consists of multiple servers
# which will receive traffic
resource "aws_lb" "test-loadbalancer" {
    name                    = "test-loadbalancer"
    load_balancer_type      = "application"
    subnets                 = data.aws_subnet_ids.default.ids
    # Tells the aws_lb which security group to use            
    security_groups         = [aws_security_group.alb-sec-group.id]
  
}

# A loadbalancer listener ist required since the system consists of multiple servers
# which will receive traffic. Must be binded with the LB listener rule.
resource "aws_lb_listener" "test-http" {
    load_balancer_arn   = aws_lb.test-loadbalancer.arn
    port                = 80
    protocol            = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
          content_type  = "text/plain"
          message_body  = "404: page not found"
          status_code   = 404
      }
    }
  
}

# Adds a listener rule that send requests that match any path to target group 
# that contains the ASG. 
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.test-http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.test-target-group.arn
    }
  
}

# AWS resources, by default, don't allow incomming/outgoing traffic
# so that a security group specific for the lb is required
resource "aws_security_group" "alb-sec-group" {
    name = "alb-sec-group"
    
    ingress {
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 80
        to_port = 80
        protocol = "tcp"
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# It will health check all the instances periodically. It must be binded with the ASG
# using "target_group_arns"
resource "aws_lb_target_group" "test-target-group" {
    name        = "target-group"
    port        = var.server_port
    protocol    = "HTTP"
    vpc_id      = data.aws_vpc.default.id

    health_check {
      path                      = "/"
      protocol                  = "HTTP"
      matcher                   = "200"
      interval                  = 15
      timeout                   = 3
      healthy_threshold         = 2
      unhealthy_threshold       = 2
    }   
  
}

output "alb_dns_name" {
    value = aws_lb.test-loadbalancer.dns_name
    description = "The domain name of the load balancer."
  
}
variable "server_port" {
    description     = "The port the server wil use for test-HTTP requests."
    type            = number
    default         = 8080
  
}
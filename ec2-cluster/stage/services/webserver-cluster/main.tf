provider "aws" {
    region                          = var.region
}

# An autoscaling group requires:
# - a launch configurarion,
# - a load balancer,
# - a security group and subnet.

resource "aws_autoscaling_group" "autoscaling" {
    # Bindes the ALC to the ASG.
    launch_configuration            = aws_launch_configuration.launch_config.name
    vpc_zone_identifier             = data.aws_subnet_ids.default.ids
    # It tells the target-group which instances to send requests to.
    target_group_arns               = [aws_lb_target_group.target-group.arn]
    health_check_type               = "ELB"
    min_size                        = 2
    max_size                        = 3
    tag {
        key                         = "Name"
        value                       = "asg"
        propagate_at_launch         = true
    }
}

resource "aws_launch_configuration" "launch_config" {
    image_id                        = "ami-0c55b159cbfafe1f0"
    instance_type                   = "t2.micro"
    # Instructs the ec2 instance to use the security group.
    # A security group acts as a virtual firewall to control inbound and outbound traffic.
    # If we don't assign a security group, the EC2 instance is assigned to the default SC.
    security_groups                 = [aws_security_group.security-group.id]
    # user_data = data.template_file.user_data.rendered
    # user_data = <<-EOF
    #             #!/bin/bash
    #             echo "hello, World!"> index.html
    #             echo "${data.terraform_remote_state.db.outputs.address}" >> index.html
    #             echo "${data.terraform_remote_state.db.outputs.port}" >> index.html
    #             nohup busybox test-httpd -f -p ${var.server_port} &
    #             EOF
    # Makes sure that a replacement for a specific resource will be created before
    # this resource gets deleted.
    lifecycle {
      create_before_destroy         = true
    }
}

# An auto scaling group needs to know in which VPC and subnets the EC2
# instances will to be deployed. The bellow resources act like filters.
data "aws_vpc" "default" {
    default                         = true
}

data "aws_subnet_ids" "default" {
    vpc_id                          = data.aws_vpc.default.id

}
# AWS resources, by default, don't allow incomming/outgoing traffic. For
# this, a security group is required. This SG must be referenced in the LC.
resource "aws_security_group" "security-group" {
    name                            = "general-security-group"
    ingress {
        from_port                   = var.server_port
        to_port                     = var.server_port
        protocol                    = "tcp"
        #cidr_blocks allow to specify IP adress ranges.
        cidr_blocks                 = ["0.0.0.0/0"]
    }
}

# A load balancer requires:
# - a security group,
# - a load balancer listener,
# - a load balancer listener rule,
# - a load balancer target group.

# A loadbalancer is required because the system will consist of multiple servers.
resource "aws_lb" "loadbalancer" {
    name                            = "loadbalancer"
    # There are multiple types of LB (Application, Network, Gateway, Classic).
    load_balancer_type              = "application"
    subnets                         = data.aws_subnet_ids.default.ids
    # Tells the LB which security group to use.
    security_groups                 = [aws_security_group.alb-sec-group.id]
}

# The load balancer listener must be binded to the load balancer listener rule.
resource "aws_lb_listener" "test-http" {

    # "ARN (Amazon Resource Name)" identifies a resource iniquely.
    load_balancer_arn               = aws_lb.loadbalancer.arn
    port                            = 80
    protocol                        = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
          content_type              = "text/plain"
          message_body              = "404: page not found"
          status_code               = 404
      }
    }
}

# this listener rule send requests that match any path of the target group
# that contains the ASG.
resource "aws_lb_listener_rule" "asg" {
    listener_arn                    = aws_lb_listener.test-http.arn
    priority                        = 100

    condition {
        path_pattern {
            values                  = ["*"]
        }
    }

    action {
        type                        = "forward"
        target_group_arn            = aws_lb_target_group.target-group.arn
    }

}

# This security group is binded to the LB.
resource "aws_security_group" "alb-sec-group" {
    name                            = "alb-sec-group"

    ingress {
        cidr_blocks                 = [ "0.0.0.0/0" ]
        from_port                   = 80
        to_port                     = 80
        protocol                    = "tcp"
    }

    egress {
        from_port                   = 80
        to_port                     = 80
        protocol                    = "tcp"
        cidr_blocks                 = [ "0.0.0.0/0" ]
    }
}

# It will health check all the instances periodically.
# It must be binded with the ASG using "target_group_arns".
resource "aws_lb_target_group" "target-group" {
    name                            = "target-group"
    port                            = var.server_port
    protocol                        = "HTTP"
    vpc_id                          = data.aws_vpc.default.id

    health_check {
      path                          = "/"
      protocol                      = "HTTP"
      matcher                       = "200"
      interval                      = 15
      timeout                       = 3
      healthy_threshold             = 2
      unhealthy_threshold           = 2
    }
}

# This configures the web server cluster to read the state file
# from the same bucket and folder where the db stores it.
data "terraform_remote_state" "db" {
    backend                         = "s3"
    config                          = {
        bucket                      = var.bucket_name
        key                         = var.bucket_key
        region                      = var.region
    }
}

# The script needs dynamic data from terraform and uses
# referebces and interpolation to fill in the values but
# for this doent work with file function, an template it needed.
# data "template_file" "user_data" {
#     template = file("user_data.sh")

#     vars = {
#         server_port = var.server_port
#         db_address = data.terraform_remote_state.db.outputs.address
#         db_port = data.terraform_remote_state.db.outputs.port 
#     }
# }
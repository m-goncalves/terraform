resource "aws_launch_configuration" "cluster_webservers_lc" {
  image_id        = "ami-08c40ec9ead489470"
  instance_type   = var.instance_type
  security_groups = [aws_security_group.cluster_webservers_sg.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster_webservers_asg" {
  launch_configuration = aws_launch_configuration.cluster_webservers_lc.name
  vpc_zone_identifier  = data.aws_subnets.subnets_default_vpc.ids
  target_group_arns    = [aws_lb_target_group.lb_target_group.arn]
  health_check_type    = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

}

resource "aws_lb" "cluster_webservers_lb" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.subnets_default_vpc.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http_lb_listener" {
  load_balancer_arn = aws_lb.cluster_webservers_lb.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "lb_listener_rule" {
  listener_arn = aws_lb_listener.http_lb_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.cluster_name}-alb"

}

resource "aws_security_group_rule" "allow_http_inboud"{
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outoud"{
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips 
}

    
  
resource "aws_security_group" "cluster_webservers_sg" {
  name = var.cluster_name
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
  }
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

terraform {
  backend "s3" {
    bucket = "tfur-state"
    key = "global/s3/stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tf-state"
    encrypt = "true"
  }
}
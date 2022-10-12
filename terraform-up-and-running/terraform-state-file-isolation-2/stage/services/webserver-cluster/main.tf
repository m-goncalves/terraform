

provider "aws" {
  region                   = "us-east-1"
}

resource "aws_launch_configuration" "cluster_webservers_lc" {
  image_id        = "ami-08c40ec9ead489470"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.cluster_webservers_sg.id]

  user_data = templatefile("user-data.sh", {
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

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "cluster_webservers_asg"
    propagate_at_launch = true
  }

}

resource "aws_lb" "cluster_webservers_lb" {
  name               = "cluster-servers-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.subnets_default_vpc.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http_lb_listener" {
  load_balancer_arn = aws_lb.cluster_webservers_lb.arn
  port              = 80
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
  name     = "lb-target-group"
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
  name = "alb_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cluster_webservers_sg" {
  name = "cluster_webservers_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
  }
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
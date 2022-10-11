terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}

resource "aws_security_group" "webserver_sg" {
  name = "webserver_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
  }

}
resource "aws_instance" "webserver" {
  ami                    = "ami-08c40ec9ead489470"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver_sg.id]
  user_data              = file("./user-data.sh")
  tags = {
    "Name" = "webserver"
  }
}

variable "server_port" {
  description = "The port the server will use for http requests"
  type        = number
  default     = 8080
}

output "public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.webserver.public_ip

}
provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "blur-instance" {
    ami                 = "ami-0c55b159cbfafe1f0"
    instance_type       = "t2.micro"
    #tells the ec2 instance to use the security group. It creates an implicit dependency
    # value inside brackets dont need "" . Why?
    vpc_security_group_ids = [aws_security_group.blur-security-group.id]
    
    tags = {
      "Name" = "blur-instance"
    }
    user_data = <<-EOF
                #!/bin/bash
                echo "hello, World!"> index.html
                nohub busybox httpd -f -p ${var.server_port} &
                EOF
}

# necessary to allow incoming traffic
resource "aws_security_group" "blur-security-group" {
    name = "blur-instance"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        #cidr_blocks allow to specify IP adress ranges
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

output "public_ip" {
    value           = aws_instance.blur-instance.public_ip
    description     = "The public IP of the web server!" 
    # important to instruct terraform not to log sensitive data
    sensitive = false
  
}
variable "server_port" {
    description     = "The port the server wil use for HTTP requests."
    type            = number
    default         = 8080
  
}
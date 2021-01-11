provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "single-instance" {
    # Specifies the image to be used.
    ami                 = "ami-0c55b159cbfafe1f0"
    instance_type       = "t2.micro"
    #tells the ec2 instance to use the security group. It creates an implicit dependency
    # value inside brackets dont need "" . Why?
    vpc_security_group_ids = [aws_security_group.si-security-group.id]
    
    tags = {
      "Name" = "single-instance"
    }

    # "<<-EOF ... EOF" makes possible to use multi-line strings. 
    user_data = <<-EOF
                #!/bin/bash
                echo "hello, World!"> index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
}

# Necessary to allow incoming traffic.
resource "aws_security_group" "si-security-group" {
    name = "single-instance"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        #cidr_blocks is required to specify IP adress ranges.
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

output "public_ip" {
    value           = aws_instance.single-instance.public_ip
    description     = "The public IP of the web server!" 
    # Can be used to instruct terraform not to log sensitive data
    sensitive = false
  
}
variable "server_port" {
    description     = "The port the server wil use for HTTP requests."
    type            = number
    default         = 8080
  
}
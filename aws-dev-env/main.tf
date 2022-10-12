resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "dev_pub_sub" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_pub"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "dev_pub_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_pub_rt"
  }
}

resource "aws_route" "dev_rt" {
  route_table_id         = aws_route_table.dev_pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "pub_rt_assoc" {
  subnet_id      = aws_subnet.dev_pub_sub.id
  route_table_id = aws_route_table.dev_pub_rt.id
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "security group of the dev environment"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.developer_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "dev_key" {
  key_name   = "dev_key"
  public_key = file("~/.ssh/dev-key.pub")
}

resource "aws_instance" "dev_instance" {
  instance_type = "t2.micro"
  ami           = var.server_os == "ubuntu" ? data.aws_ami.dev_server_ubuntu.id : data.aws_ami.dev_server_centos.id
  #ami                    = data.aws_ami.dev_server_ami.id
  key_name               = aws_key_pair.dev_key.id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  subnet_id              = aws_subnet.dev_pub_sub.id
  user_data              = file(var.server_os == "ubuntu" ? "user-data-ubuntu.sh" : "user-data-amz.sh")
  #user_data = file("user-data-ubuntu.sh")

  root_block_device {
    volume_size = 10
  }

  provisioner "local-exec" {
    command = templatefile("unix-config.tpl", {
      hostname     = self.public_ip,
      user         = var.server_os == "ubuntu" ? "ubuntu" : "ec2-user"
      identityfile = var.dev_ssh_key
    })
    interpreter = var.host_os == "linux" ? ["bash", "-c"] : ["zsh", "-c"]
  }

  tags = {
    Name = "dev_instance"
  }

}
provider "aws" {
    region = "us-east-1"
    alias = "region_1"
}

provider "aws" {
    region = "us-east-2"
    alias = "region_2"
}

resource "aws_instance" "instance_rg_1" {
    provider = aws.region_1
    ami = data.aws_ami.ubuntu_region_1.id
    instance_type = "t2.micro"
}

resource "aws_instance" "instance_rg_2" {
    provider = aws.region_2
    ami = data.aws_ami.ubuntu_region_2.id
    instance_type = "t2.micro"
}
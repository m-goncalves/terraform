data "aws_availability_zones" "az" {
    state = "available"
}

data "aws_subnet_ids" "subnets" {
    vpc_id = var.vpc_id
}

data "aws_vpc" "vpc" {
    id = var.vpc_id
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = [099720109477]
}

data "templete_file" "docker_compose" {
    template = file("./templates/docker-compose.tlp")

    vars = {
        db_host = aws_rds_cluster.wordpres.endpoint
        db_user = aws_rds_cluster.wordpres.master_username
        db_name = aws_rds_cluster.wordpress.database_name
        db_password = aws_rds_cluster.wordpres.master_password
        external_port = var.wordpress_external_port
    }
}
data "templete_file" "nginx_conf" {
    template = file("./templates/nginx-conf.tlp")

    vars = {
        external_port = var.wordpress_external_port
    }
}

data "template_file" "userdata" {
  template = file("./template/userdata.tpl")

  vars = {
    dockercompose = data.template_file.dockercompose.rendered
    nginx_conf    = data.template_file.nginx_conf.rendered
  }

}



resource "aws_rds_cluster" "wordpress" {
  cluster_identifier      = "wordpress-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = data.aws_availability_zones.az.availability_zones
  database_name           = aws_ssm_parameter.db_name.value
  master_username         = aws_ssm_parameter.db_user.value
  master_password         = aws_ssm_parameter.db_password.value
  db_subnet_group_name = aws_db_subnet_group.db_subnet.id 
  engine_mode = "serverless"
  vpc_security_groups_ids =  ""

  scaling_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  tags = local.tags
}

resource "aws_instance" "wordpres" {
  ami = data.aws.ami.ubuntu.id
  instance_type = var.ec2.instance_type
  associate_public_ip_adress = true
  subnet_id = sort(data.aws_subnet_ids.subnets.ids)[0]
  security_groups = [aws_security_group.ec2_sec_group.id]
  user_data = data.templete_cloudint_config.userdata.rendered
  
  tags = merge(locals.tags, {
    Name = "wordpress-instance"
  })
}

resource "aws_security_group" "rds_sec_group" {
  name = "wordpress rds access"
  description "rds sg"
  vpc_id = var.vpc_id

  ingress {
    description "VPC bound"
    from_port = "3306"
    to_port = "3306"
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = locals.tags
}

resource "aws_security_group" "ec2_sec_group" {
  name = "wordpress_instance_sg"
  description "ec2 sg"
  vpc_id = var.vpc_id

  ingress {
    description = "VPC bound"
    from_port = var.wordpress_external_port
    to_port = var.wordpress_external_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = locals.tags
}



resource "aws_db_subnet_group" "db_subnet" {
  name = "wordpress_cluster_subnet"
  description =  "Aurora wordpress cluster db group"
  subnet_ids = data.aws_subnet_ids.subnets.subnet_ids
  tags = local.tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/app/wordpress/DATABASE_NAME"
  type  = "String"
  value = var.database_name
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/app/wordpress/DATABASE_MASTER_USERNAME"
  type  = "String"
  value = var.database_master_username
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/app/wordpress/DATABASE_MASTER_PASSWORD"
  type  = "SecureString"
  value = random_password.password.result
}

resource "random_password" {
    length = 16
    special = true
    overrid_special = "_%@"
}
provider "aws" {
    region = "sa-east-1"
}

resource "aws_db_instance" "db-instance" {
    identifier_prefix       = "db-instance"
    engine                  = "mysql"
    allocated_storage       = 10
    instance_class          = "db.t2.micro"
    name                    = "mydb"
    username                = "admin"
    password                = var.db_password 
}

data "terraform_remote_state" "db" {
    backend         = "s3"
    config          = {
        bucket      = "unique-tf-state-bucket"
        key         = "stage/data-stores/mysql/terraform.tfstate"
        region      = "sa-east-1"
    }
}
terraform {
  backend "s3" {
      bucket                = "unique-tf-state-bucket"
      key                   = "stage/data-stores/mysql/terraform.tfstate"
      region                = "sa-east-1"
      dynamodb_table        = "terraform_locks"
      encrypt               = true
  }
}


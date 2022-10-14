provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "tf_db_instance" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  db_name           = "tf_database"
  # importante para se deletar a banco de dados mais facilmente pelo terraform (apenas para testes)
  skip_final_snapshot = true
  username            = var.db_username
  password            = var.db_password

}

terraform {
  backend "s3" {
    bucket         = "tfur-state"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state"
    encrypt        = true
  }
}


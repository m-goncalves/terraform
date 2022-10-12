terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"

    }
  }
}

provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}

resource "aws_db_instance" "tf_db_instance" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  db_name              = "tf_database"
  # importante para se deletar a banco de dados mais facilmente pelo terraform (apenas para testes)
  skip_final_snapshot = true
  username = var.username
  password = var.password

}

#terraform {
#  backend "s3" {
#    bucket         = "tfur-state-bucket"
#    key            = "stage/data-stores/mysql/terraform.tfstate"
#    region         = "us-east-1"
#    dynamodb_table = "terraform-locks"
#    encrypt        = true
#  }
#}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_db_instance" "tf_db_instance" {
  identifier_prefix = "dp-of-cluster"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  backup_retention_period = var.backup_retention_period
  replicate_source_db = var.replicate_source_db
  # importante para se deletar a banco de dados mais facilmente pelo terraform (apenas para testes)
  skip_final_snapshot = true
  engine            = var.replicate_source_db == null ? "mysql" : null
  db_name           = var.replicate_source_db == null ? var.db_name : null
  username            = var.replicate_source_db == null ? var.db_username : null
  password            = var.replicate_source_db == null ? var.db_password : null
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


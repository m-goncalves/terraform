# It's better to define the database in another set of configuration files
# as the web server since the web server will be updated more often as the 
# database. 
provider "aws" {
    region = var.region
}

# Creates a MySQL DB in RDS.
resource "aws_db_instance" "db-instance" {
    identifier_prefix       = "db-instance"
    engine                  = "mysql"
    allocated_storage       = 10
    instance_class          = "db.t2.micro"
    name                    = "mydb"
    username                = "admin"
    password                = var.db_password
    # One more way of handling secrets 
    # password                = data.aws_secretsmanager_secret_version.db_password.secrt_string
}
# data "aws_secretsmanager_secret_version" "db_password" {
#     secret_id = "mysql-master-password-stage" 
# }

terraform {
  backend "s3" {
      bucket                = "us-unique-tf-state-bucket"
      key                   = "stage/data-stores/mysql/terraform.tfstate"
      region                = "us-east-2"
      dynamodb_table        = "terraform_locks"
      encrypt               = true
  }
}


provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Owner     = "dev-team"
      ManagedBy = "terraform"
    }
  }
}

module "webserver_cluster" {
  source                 = "../../../../modules/services/webserver-cluster"
  ami                    = "ami-08c40ec9ead489470"
  server_text            = "New server text"
  cluster_name           = "cluster-webservers-stage"
  db_remote_state_bucket = "tfur-state"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
  instance_type          = "t2.micro"
  min_size               = 2
  max_size               = 2
  enable_autoscaling     = false

  custom_tags = {
    Owner     = "dev-team"
    ManagedBy = "terraform"
  }
}
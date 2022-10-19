module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "cluster-webservers-prod"
  db_remote_state_bucket = "truf-state-bucket"
  db-db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  instance_type          = "t2.micro"
  min_size               = 2
  max_size               = 2
  enable_autoscaling     = true
  custom_tags = {
    Owner     = "dev-team"
    ManagedBy = "terraform"
  }
} 
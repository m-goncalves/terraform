provider "aws" {
    region = "us-east-1"
}
module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
    cluster_name = "cluster-webservers-stage"
    db_remote_state_bucket = "tfur-state"
    db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
    instance_type = "t2.micro"
    min_size = 2
    max_size = 2  
}
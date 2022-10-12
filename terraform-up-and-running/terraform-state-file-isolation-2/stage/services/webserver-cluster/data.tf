data "aws_vpc" "default_vpc" {
  default = true


}
data "aws_subnets" "subnets_default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "tfur-state"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
   }
  
}
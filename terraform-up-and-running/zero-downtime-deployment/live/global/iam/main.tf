provider "aws" {
  region = "us-east-2"

}
resource "aws_iam_user" "webserver_iam" {
  for_each = toset(var.user_names)
  name     = each.value
}

#module "users" {
#source = "../../../modules/landing-zone/iam-user"
#count = length(var.user_names)
#user_name = var.user_names[count.index]
#  
#}
#output "user_arns" {
    #value = module.users[*].user_arn
#}

output "all_arns" {
    value = values(aws_iam_user.webserver_iam)[*].arn
}
output "user_arn" {
    value = aws_iam_user.webserver-cluster.arn
    description = "The arn of the created IAM user"
}
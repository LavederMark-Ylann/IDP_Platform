output "terraform_iam_role_arn" {
  value = aws_iam_role.terraform_networkrole.arn
}

output "terraform_iam_role_name" {
  value = aws_iam_role.terraform_networkrole.name
}
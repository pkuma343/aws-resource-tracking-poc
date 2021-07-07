output "Lambda_IAM_Role" {
  value = aws_iam_role.lambda_get_resources_role.id
}
output "Lambda_Function" {
  value = aws_lambda_function.lambdaFuncGetResources.arn
}
output "Event_Rule" {
  value = aws_cloudwatch_event_rule.get_resources_rule.arn
}
variable "Region" {
    default = "us-west-1"
}
variable "fromMail" {
    default = "shraddha.jain@nagarro.com"
}
variable "file" {
    default = "resources.csv"
}
variable "toMail" {
    default = "shraddha.jain@nagarro.com"
}
variable "FUNCTION_NAME" {
    default = "lambdaFuncGetResources"
}
variable "lambdaRole" {
    default = "lambda_get_resources_role"
}
variable "lambdaPolicy" {
    default = "lambda_get_resources_policy"
}
variable "event_rule" {
    default = "get_resources_rule"
}
variable "cron"{
    default = "cron(48 11 * * ? *)"
}
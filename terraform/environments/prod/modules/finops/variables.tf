variable "budget_name" {
  type    = string
  default = "idp-platform-monthly-budget"
}

variable "monthly_limit_usd" {
  type    = number
  default = 50
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "project_tag" {
  type    = string
  default = "IDP_Platform"
}
variable "default_region" {
  type    = string
  default = "us-east-1"
}

variable "default_spot_notification_email_address" {
  default = ""
  type    = string
}

variable "my_trusted_ips" {
  type = list(string)
}
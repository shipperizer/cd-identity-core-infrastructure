variable "workers" {
  type    = number
  default = 3
}

variable "controls" {
  type    = number
  default = 2
}

variable "https_proxy" {
  type    = string
  default = "http://squid.ps6.internal:3128"
}

variable "http_proxy" {
  type    = string
  default = "http://squid.ps6.internal:3128"
}
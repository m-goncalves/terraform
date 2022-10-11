variable "host_os" {
  type    = string
  default = "macos"
}

variable "server_os" {
  type    = string
  default = "ubuntu"
}
variable "dev_ssh_key" {
  type    = string
  default = "~/.ssh/dev-key"
}

variable "developer_ip" {
  type        = string
  default     = "93.198.248.95/32"
  description = "IP of the developer to added to the aws security group."
}


variable database_name {
  type        = string
  default     = ""
  description = "description"
}

variable database_master_username {
  type        = string
  default     = ""
  description = "description"
}

variable "vpc_id" {
  type        = string
  description = "description"
}

variable "cluster_instance_class" {
  description = "instance class for rds"
  type = "string"
  default = "db.t2.micro"
}
variable "wordpress_external_port" {
  type        = number
  default     = 80
  description = "wordpres port"
}

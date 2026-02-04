variable "resource_group_name" {
  type = string
}

variable "enabled_stacks" {
  type    = set(string)
  default = []
}

variable "name" {}
variable "layers" {
  type = list(string)
}
variable "runtime" {}
variable "build_dir" {}
variable "memory_size" {
  default = "128"
}
variable "handler" {
  default = "index.handler"
}
variable "vault-parent-namespace" {
  type    = string
  default = ""
}

variable "azure_location" {
  type    = string
  default = "westeurope"
}

variable "secret-mount" {
  type    = string
  default = "secret"
}

variable "secret-path" {
type    = string
  default = "secret/azure"
}

variable "entra-domain" {
  type    = string
}

variable "entra-user-password" {
  type    = string
}
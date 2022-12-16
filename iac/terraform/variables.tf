# Variables which could be overrided by:
# - Azure DevOps variable group
# - *.tfvars files

variable "RESOURCE_GROUP" {
  type = string
}

variable "WORKSPACE_DISPLAY_NAME" {
  type = string
}

variable "LOCATION" {
  type = string
}

variable "IOT_EDGE_VM_USERNAME" {
  default = "edgeuser"
}

# Not in use, using ssh instead
variable "IOT_EDGE_VM_PASSWORD" {
  type = string
  default = "xxx"
}

variable "JUMPHOST_USERNAME" {
  default = "azureuser"
}

variable "JUMPHOST_PASSWORD" {
  type = string
}
variable "AGENT_USERNAME" {
  default = "azureuser"
}

variable "AGENT_PASSWORD" {
  type = string
  default = "Password1234"
}

variable "AGENT_POOL" {
  type = string
}

variable "ADO_PAT" {
  type = string
}
variable "ADO_ORG_SERVICE_URL" {
  type = string
}

variable "AML_COMPUTE_TARGET" {
  type = string
}

variable "AML_COMPUTE_TARGET_VM_SIZE" {
  type = string
  default = "Standard_NC6s_v3"
}
variable "PREFIX" {
  type = string
}

variable "REGION" {
  type = string
}

variable "ENV" {
  type = string
}

variable "AGENT_COUNT" {
  type = number
  default = 2
}

resource "random_string" "postfix" {
  length = 6
  special = false
  upper = false
}
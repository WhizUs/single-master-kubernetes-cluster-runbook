terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}

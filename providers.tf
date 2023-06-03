terraform {
    required_providers {
      oci = {
        source  = "oracle/oci"
        version = "~> 4.122.0"
      }
    }
    cloud {
      organization = "scottiepowell"

    workspaces {
      name = "oci-kubernetes"
    }
  }
}
provider "oci" {
  tenancy_ocid     = var.compartment_id
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  region           = var.region
  private_key_path = file(var.private_key_path)
}
provider "kubernetes" {
  config_path = var.kube_config_path
}
provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}

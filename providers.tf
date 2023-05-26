terraform {
    required_providers {
      oci = {
        source  = "oracle/oci"
        version = "~> 4.122.0"
      }
      kubectl = {
        source  = "gavinbunney/kubectl"
        version = "~> 1.14.0"
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
provider "kubectl" {
  host                   = var.oci_cluster_endpoint
  cluster_ca_certificate = base64decode(var.certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", var.cluster_id, "--region", var.region]
  }
}

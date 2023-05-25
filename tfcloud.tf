terraform {
  cloud {
    organization = "scottiepowell"

    workspaces {
      name = "oci-kubernetes"
    }
  }
}
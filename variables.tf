variable "region" {
  type        = string
  description = "The region to provision the resources in"
}
variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}
variable "public_subnet_id" {
  type = string
  description = "The public subnet's OCID"
}
variable "node_pool_id" {
  type = string
  description = "The OCID of the Node Pool where the compute instances reside"
}
variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to use for connecting to the worker nodes"
}
variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}
variable "fingerprint" {
  description = "The fingerprint of the public key added in the OCI user's API settings. Used for authentication in conjunction with the private key."
  type        = string
}
variable "private_key_path" {
  description = "The path to the private key associated with the API key"
  type        = string
}
variable "kube_config_path" {
  description = "kubeconfig location for cluster"
  type        = string
}
variable "certificate_authority_data" {
  description = "The certificate authority data from kubeconfig"
  type        = string
}
variable "cluster_id" {
  description = "Cluster ID from OCID"
  type        = string
}
variable "oci_cluster_endpoint" {
  description = "Cluster ID from OCID"
  type        = string
}
variable "project_dir" {
  description = "directory home of the project"
  type        = string
}

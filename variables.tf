variable "region" {
  type        = string
  description = "The region to provision the resources in"
}
variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
  #default="ocid1.tenancy.oc1..aaaaaaaao6x7uwzfuasfh5ia5qz4zhw4j7oxl6hkhxq4vc7vdqchyxde3una"
}
variable "public_subnet_id" {
  type = string
  description = "The public subnet's OCID"
  default ="ocid1.subnet.oc1.phx.aaaaaaaa3ir55oy6lbkn2n4j4txltw7lezer37ghdihdz6shkgnrdtevvjoq"
}
variable "node_pool_id" {
  type = string
  description = "The OCID of the Node Pool where the compute instances reside"
  default = "ocid1.nodepool.oc1.phx.aaaaaaaaboestqqfh2rzwjpzyha67chmeoigolfpeqv33rb7pnunic4tkqba"
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



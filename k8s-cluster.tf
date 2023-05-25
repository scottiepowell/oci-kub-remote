provider "kubernetes" {
  config_path = var.kube_config_path
}

resource "kubernetes_namespace" "idp_namespace" {
  metadata {
    name = "idp-ns"
  }
}
data "oci_containerengine_node_pool" "idp_k8s_np" {
  node_pool_id = var.node_pool_id
}
locals {
  active_nodes = [for node in data.oci_containerengine_node_pool.idp_k8s_np.nodes : node if node.state == "ACTIVE"]
}
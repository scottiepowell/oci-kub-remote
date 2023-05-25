resource "oci_network_load_balancer_network_load_balancer" "idp_nlb" {
  compartment_id = var.compartment_id
  display_name   = "idp-k8s-nlb"
  subnet_id      = var.public_subnet_id
  is_private                     = false
  is_preserve_source_destination = false
}
resource "oci_network_load_balancer_backend_set" "idp_nlb_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 10256
  }
  name                     = "idp-k8s-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.idp_nlb.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source = false
}
resource "oci_network_load_balancer_backend" "free_nlb_backend" {
  count                    = length(local.active_nodes)
  backend_set_name         = oci_network_load_balancer_backend_set.idp_nlb_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.idp_nlb.id
  port                     = 31600
  target_id                = local.active_nodes[count.index].id
}
resource "oci_network_load_balancer_listener" "idp_nlb_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.idp_nlb_backend_set.name
  name                     = "idp-k8s-nlb-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.idp_nlb.id
  port                     = "80"
  protocol                 = "TCP"
}
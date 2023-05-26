module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.5.4"

  compartment_id = var.compartment_id
  region         = var.region

  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null

  vcn_name      = "idp-k8s-vcn"
  vcn_dns_label = "idpk8svcn"
  vcn_cidrs     = ["10.0.0.0/16"]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
}

resource "oci_core_subnet" "vcn_private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.1.0/24"
  route_table_id             = module.vcn.nat_route_id
  security_list_ids          = [oci_core_security_list.private_subnet_sl.id]
  display_name               = "idp-k8s-private-subnet"
  prohibit_public_ip_on_vnic = true
}
resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.0.0/24"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public_subnet_sl.id]
  display_name      = "idp-k8s-public-subnet"
}

resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.26.2"
  name               = "idp-k8s-cluster"
  vcn_id             = module.vcn.vcn_id
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
}
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}
resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.26.2"
  name               = "idp-k8s-node-pool"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    size = 2
  }
  node_shape = "VM.Standard.A1.Flex"
  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  node_source_details {
    image_id    = "ocid1.image.oc1.phx.aaaaaaaaacbbfxlxxvgad32qebxudow6snl5beje6pzubhiqc4jtll67xpjq"
    source_type = "image"
  }
  initial_node_labels {
    key   = "name"
    value = "idp-k8s-cluster"
  }
  ssh_public_key = var.ssh_public_key
}


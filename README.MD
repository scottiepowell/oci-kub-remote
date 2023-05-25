# oci-kubernetes

This is a Terraform project for deploying a Kubernetes cluster on Oracle Cloud Infrastructure (OCI). The code provisions a Virtual Cloud Network (VCN) with public and private subnets, sets up the Kubernetes cluster, and creates a node pool within it. All resources are managed in the OCI compartment provided.

## Prerequisites

-   [Terraform](https://www.terraform.io/downloads.html) v0.13 or later.
-   [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
-   [kubectl](https://kubernetes.io/docs/tasks/tools/) for managing the Kubernetes cluster
-   [OCI account](https://cloud.oracle.com/en_US/tryit)

## Environment Variables

Export the following environment variables. You can typically retrieve these from the OCI console under user settings.

bash

`export OCI_TENANCY_ID=<tenancy_ocid> export OCI_USER_ID=<user_ocid> export OCI_FINGERPRINT=<fingerprint> export OCI_REGION=<region> export OCI_PRIVATE_KEY_PATH=<private_key_path> export OCI_SSH_PUBLIC_KEY=<ssh_public_key> export OCI_NODE_POOL_ID=<node_pool_id> export OCI_KUBE_CONFIG_PATH=<kube_config_path>`

## Configuring kubectl

Ensure that the kubectl tool is installed. Use the following command to check:

bash

`kubectl version --client`

If you see the version, then kubectl is installed. If not, please install it following [these instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

To set up access to the Kubernetes cluster, you need a kubeconfig file. In this project, the kubeconfig is supposed to be provided through the `var.kube_config_path` variable. Please ensure to correctly set the environment variable `OCI_KUBE_CONFIG_PATH` to point to your kubeconfig file.

## Installing OCI CLI

You can install the OCI CLI using the following command:

`bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"`

Please follow the prompts to proceed with the installation.

## Running the code

Initialize the Terraform workspace:

`terraform init`

Plan the deployment:

`terraform plan`

Apply the changes to reach the desired state of the configuration:

`terraform apply`

## Code walkthrough

The Terraform code outlined here involves several key stages of setting up and configuring a Kubernetes cluster in the Oracle Cloud Infrastructure (OCI).

### Kubernetes Provider and Namespace

The process begins by setting up a Kubernetes provider and indicating the path to the kubeconfig file. This is performed with:

`provider "kubernetes" {   config_path = var.kube_config_path }`

Then, a namespace `idp-ns` is created in the Kubernetes cluster:

`resource "kubernetes_namespace" "idp_namespace" {   metadata {     name = "idp-ns"   } }`

### Node Pool Information

The code pulls information about a node pool from OCI, storing a list of active nodes in the `active_nodes` local variable:

`data "oci_containerengine_node_pool" "idp_k8s_np" {   node_pool_id = var.node_pool_id } locals {   active_nodes = [for node in data.oci_containerengine_node_pool.idp_k8s_np.nodes : node if node.state == "ACTIVE"] }`

### OCI Provider and VCN Configuration

The code then configures the OCI provider, and sets up a Virtual Cloud Network (VCN) using the `oracle-terraform-modules/vcn/oci` module. The VCN includes an Internet Gateway, NAT Gateway, and Service Gateway. Additionally, it sets up two subnets: one public and one private:

`provider "oci" {   tenancy_ocid     = var.compartment_id   user_ocid        = var.user_ocid   fingerprint      = var.fingerprint   region           = var.region   private_key_path = file(var.private_key_path) }`

The VCN and subnet configuration is done using:

```
module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

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
```

### Kubernetes Cluster Creation

A Kubernetes cluster is then created in the VCN. Public access is enabled, and the public subnet is specified as its endpoint. The pod and service CIDRs are defined, and the public subnet is indicated for load balancer services:

```
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
```

## Node Pool Configuration

The script fetches the list of availability domains in the compartment and sets up a node pool with nodes in the first three availability domains. The nodes are placed in the private subnet and are configured with the image specified in `node_source_details`.

First, availability domains are fetched with:


`data "oci_identity_availability_domains" "ads" {   compartment_id = var.compartment_id }`

Then the node pool is set up:
```
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
```
Each node in the node pool has a configuration of 6 GB memory and 1 OCPU:

  `node_shape_config {     memory_in_gbs = 6     ocpus         = 1   }`

Node source details specify the image used for nodes:


  `node_source_details {     image_id    = "ocid1.image.oc1.phx.aaaaaaaaacbbfxlxxvgad32qebxudow6snl5beje6pzubhiqc4jtll67xpjq"     source_type = "image"   }`

Each node is labeled with the key "name" and the value "idp-k8s-cluster", and the SSH public key specified in the variable `ssh_public_key` is used:


  `initial_node_labels {     key   = "name"     value = "idp-k8s-cluster"   }   ssh_public_key = var.ssh_public_key }`

In conclusion, this code will provision an Oracle Cloud Infrastructure environment, setting up a VCN, a Kubernetes cluster within it, and a node pool configured to specifications.

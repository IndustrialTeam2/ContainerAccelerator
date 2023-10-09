# This adds the helm provider to the Terraform configuration
#
# Arguments:
# - `kubernetes`: The Kubernetes configuration for the provider.
#    * `host`: The endpoint for the Kubernetes API server.
#    * `cluster_ca_certificate`: The CA certificate for the Kubernetes cluster.
# - `exec`: Used for authenticating to the Kubernetes cluster.
provider "helm" {
    kubernetes {
      host = module.eks.cluster_endpoint
      cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
    }
}

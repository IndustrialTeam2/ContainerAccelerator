# Container Accelerator Code Documentation

This guide is intended to help future developers understand the codebase of the Container Accelerator, and simplify onboarding and maintenance efforts.  
It contains details on all of the code written in the Terraform files.

> Please note that the Technical Manual on how to use the software is separate and contained in the repository README file. Whereas the manual explains how to use it, this code documentation explains how it works behind the scenes.

## Summary of the file structure
To improve readability and modularity, the code is split up into files as follows:

| File | Area of application | Description |
| - | - | - |
| main.tf | Terraform configuration | Contains the AWS resource initialisation
| eks.tf | Cluster configuration | Contains the EKS module for creating the cluster
| vpc.tf | Cluster configuration | Contains the VPC module for managing the isolated cloud network
| kubernetes.tf | Cluster configuration | Sets up the kubectl utility by requesting credentials from AWS
| ingress_controller.tf | Cluster configuration | Enables AWS ELB default ingress
| karpenter.tf | Autoscaling | Enables autoscaling with the Karpenter provider
| prometheus.tf | Monitoring | Installs Prometheus onto the K8s cluster
| prometheus.yaml | Monitoring | Contains the Prometheus configuration 
| py-requirements.txt | Testing | Initialises the modules used in infrastructure testing 
| test_cluster_configuration.py | Testing | Runs automated tests to check the state of the infrastructure
| aws_roles.tf | Security | Creates segregated roles within AWS
| helm.tf | Deployment configuration | Uses the Helm provider for automatic deployment of WordPress
| wordpress.yml | Deployment configuration | Deployment settings for WordPress itself
| rds.tf | Deployment configuration | Contains the configuration to set up a database for deployed services
| variables.tf | Input configuration | Contains all modifiable parts of the deployment configuration

## main.tf file
The main.tf file is responsible for the base configuration of AWS. It specifies the AWS provider and contains the variable for setting the AWS region.

### AWS resource
#### Current configuration
The region is set through a variable. It should not be modifed in the code in order to not break the overall project configuration. Instead, set the region through the provided Terraform variable.

!> Security note: It is possible to specify the AWS credentials here, however it's strongly advised not to that. Instead use a configuration file separate from the codebase.

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's AWS documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs  

## eks.tf file
The eks.tf file sets up cluster details such as the cluster name and connects with related configurations such as the VPC using references.

### EKS module
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| source | Specifies the Terraform registry module name
| version | Version of the Terraform registry module
| version | Version of the Terraform registry module
| cluster_name | The name of the cluster managed by a variable
| vpc_id | Automatically generated VPC ID
| subnet_ids | Private VPC subnets where the cluster operates
| subnet_ids | Private VPC subnets where the cluster operates
| cluster_endpoint_private_access | Enables private access to the cluster from the subnet
| cluster_endpoint_public_access | Enables public access to the cluster from the load balancer
| eks_managed_node_groups | Describes the cluster nodes, including minimum and maximum number of nodes, and instance types
| manage_aws_auth_configmap | Enables the Config Map for Karpenter
| AWS auth roles | Defines a role for Karpenter autoscaling
| tags | Specially-named tag enables Karpentes integration

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's AWS documentation: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest  

## vpc.tf file
The vpc.tf file sets up a private subnet where the cluster is deployed, isolated from the internet and spread across multiple availability zones.

### VPC module
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| source | Specifies the Terraform registry module name
| name | Name of the VPC managed by a variable
| azs | Availability zones where the VPC would be deployed, managed by a variable
| cidr | The VPC CIDR IP block
| private_subnets | The IP address range where the cluster nodes are deployed
| public_subnets | The IP address range which is publically accessible
| enable_nat_gateway | Enables NAT management of nodes
| single_nat_gateway | Enables NAT management of nodes
| enable_dns_hostnames | Enables DNS, making the cluster accessible via the load balancer
| enable_dns_support | Enables DNS, making the cluster accessible via the load balancer
| tags | The tags must be using the specific name as they serve to integrate with Kubernetes
| public_subnet_tags | The tags must be using the specific name as they serve to integrate with Kubernetes
| private_subnet_tags | The tags must be using the specific name as they serve to integrate with Kubernetes

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's AWS documentation: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

## kubernetes.tf file
The kubernetes.tf file configures the Kubernetes provider, sets up certificates and injects AWS credentials into the EKS CLI.

### Kubernetes provider
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| host | Specifies where the cluster is hosted, dynamically fetched
| cluster_ca_certificate | References the EKS Certificate Authority
| exec | Executes AWS CLI code to fetch the AWS token

!> The exec command requires AWS CLI command to be installed in the CI/CD environment

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's Kubernetes documentation: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs

## ingress_controller.tf file
The ingress_controller.tf file configures the ALB ingress and load balancer, which enables public access to the cluster.

### IAM role submodule
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| source | Source of the Terraform registry module
| role_name | The name of the IAM role
| attach_load_balancer_controller_policy | Attaches the policy for the load balancer
| oidc_providers | Connects the IAM role to the Kubernetes provider
| oidc_providers | Connects the IAM role to the Kubernetes provider

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's documentation: https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks

### ALB ingress controller submodule
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| name | Name of the load balancer controller
| namespace | Namespace within which the cluster is deployed
| labels | Specific labels are used to associate the ingress and load balancer
| annotations | Specific annotations are used to associate the load balancer and the IAM role

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's documentation: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account

### Helm release for the load balancer
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| name | Name of the load balancer controller
| namespace | Namespace within which the cluster is deployed
| repository | Repository of the load balancer
| depends_on | Ensures the Ingress Controller is set up as a dependency
| annotations | Specific annotations are used to associate the load balancer and the IAM role
| region | Sets the region of the load balancer
| vpc_id | Associates the VPC with the load balancer
| image.repository | Specifies the image of the load balancer container
| serviceAccount.create | Set to false as the account is already created
| serviceAccount.name |  Associates the account with the load balancer
| clusterName |  Associates the EKS cluster with the load balancer

#### Possible extensions
Further configurations, which may be exposed as variables, are available on AWS's repository for the EKS load balancer: https://aws.github.io/eks-charts

## karpenter.tf file
The karpenter.tf file enables autoscaling for the cluster, dynamically allocating new nodes.

### karpenter module
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| source | Source of the Terraform module
| cluster_name | Associates the cluster with Karpenter
| irsa_oidc_provider_arn | Associates the OIDC provider with Karpenter
| namespace | Associates the Kubernetes namespace with Karpenter
| name | Name of the Karpenter service
| repository | Repository of the Karpenter service
| repository_username | Credentials for the repository of the Karpenter service
| repository_password | Credentials for the repository of the Karpenter service
| settings.aws.clusterName | Associates the cluster with Karpenter
| settings.aws.clusterEndpoint | Associates the cluster IP address with Karpenter


#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's Kubernetes documentation: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/submodules/karpenter

## prometheus.tf file
The prometheus.tf file configures the Prometheus provider, for scraping cluster health information and passing it onto Grafana.

### Prometheus provider
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| ["namespaces","services", "pods", "endpoints", "nodes", "nodes/metrics"] | Specifies where the node metrics are published
| ["configmaps"] | Specifies where the cluster config maps are published
| ["ingresses"] | Specifies where the ingress metrics are published
| Other metrics | All other metrics are associated in a similar manner


#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's Kubernetes documentation: 
https://registry.terraform.io/modules/terraform-aws-modules/managed-service-prometheus/aws/latest

## aws_roles.tf file
The aws_roles.tf file configures the AWS roles for Developer and Admin access.

### AWS IAM provider
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| name | Name of the role
| assume_role_policy | Sets up the role properties 
| policy | Lists the permission of the role, eg. ec2:DescribeVpcs

#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's documentation: 
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role.html

!> Only the necessary permissions should be allowed to minimise chances of data leaks.

## helm.tf file
The helm.tf file configures the Helm provider, for deployment of containers.

### Prometheus provider
#### Current configuration
The currently used properties are set out below:

| Property name | Description |
| - | - |
| host | Specifies where the cluster is hosted, dynamically fetched
| cluster_ca_certificate | References the EKS Certificate Authority
| exec | Executes AWS CLI code to fetch the AWS token

!> The exec command requires AWS CLI command to be installed in the CI/CD environment


#### Possible extensions
Further configurations, which may be exposed as variables, are available on Hashicorp's documentation: 
https://registry.terraform.io/providers/hashicorp/helm/latest/docs

## variables.tf
The variables.tf file is used by the end-user, and therefore described in the Technical Manual rather than in the code documentation.
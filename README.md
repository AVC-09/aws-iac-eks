# Task & Metrics API — Infrastructure (IaC)

Production-ready infrastructure provisioning on AWS using **Terraform** and **Helm**.

## 🏗️ Architecture Overview

The infrastructure provisions a secure, highly available, and auto-scaling Kubernetes environment designed for microservices workloads.

### 1. Compute & Cluster Layer
- **Amazon EKS (v1.34):** Fully managed Kubernetes control plane.
- **AWS Graviton Nodes (`m7g`/`c7g`):** Worker nodes running on ARM64 architecture for high price-performance efficiency.
- **Spot Instance Capacity:** Node groups configured with Spot instances across multiple Availability Zones to optimize cloud spend.

### 2. Networking & Traffic Routing
- **Multi-AZ 3-Tier VPC:** Isolated subnets for Public ingress, Private application pods, and Isolated Database/Redis instances.
- **AWS Load Balancer Controller:** Provisioned via Helm to automatically configure external Application Load Balancers (ALB).
- **Direct IP Routing (`target-type: ip`):** Traffic routes directly from the ALB to individual Pod IPs, bypassing `kube-proxy` hops.

### 3. Persistence & Security
- **Amazon ElastiCache for Redis:** Managed Redis cluster provisioned inside private database subnets.
- **OIDC & IRSA (IAM Roles for Service Accounts):** Fine-grained, least-privilege IAM policies bound directly to Kubernetes Service Accounts.
- **IMDSv2 Enforcement:** Enforced token-based metadata access with a hop limit set to 2 for secure containerized operations.

### 4. Observability & Autoscaling
- **Kubernetes Metrics Server:** Deployed via Helm to scrape pod resource utilization.
- **Horizontal Pod Autoscaler (HPA):** Dynamically scales application workloads based on real-time CPU consumption.

---

## ⚖️ Design Decisions & Trade-offs

### 1. Compute Architecture: AWS Graviton (ARM64)
- **Choice:** Deployed `m7g`/`c7g` Graviton-based instances instead of x86/Intel nodes.
- **Advantages:** ~20% lower cost and up to 40% better price-performance compared to equivalent x86 instances.
- **Trade-offs & Mitigations:** Application container images must be built natively for `linux/arm64` or compiled as multi-architecture builds.

### 2. Capacity Strategy: Spot Instances
- **Choice:** Managed Node Groups utilizing AWS Spot capacity.
- **Advantages:** Up to 70–90% cost savings relative to On-Demand pricing.
- **Trade-offs & Mitigations:** Risk of node termination warnings (2-minute notification). Mitigated by spreading pods across multiple Availability Zones and maintaining `minReplicas: 2` in deployment manifests.

### 3. Ingress Routing: `target-type: ip`
- **Choice:** Configured ALB Target Groups to route directly to Pod IP addresses instead of EC2 NodePorts (`instance` mode).
- **Advantages:** Lower network latency, eliminates `kube-proxy` NAT overhead, and ensures balanced request distribution across individual pods.
- **Trade-offs & Mitigations:** Consumes VPC IP addresses from the private subnet pool. Mitigated by sizing VPC subnets with adequate CIDR masks (e.g., `/20` or `/18`).

### 4. Authentication: OIDC & IRSA
- **Choice:** Used IAM Roles for Service Accounts for both AWS Load Balancer Controller and application components.
- **Advantages:** Eliminates hardcoded long-lived AWS credentials inside cluster manifests or container images.
- **Trade-offs & Mitigations:** Slightly higher upfront Terraform code complexity compared to node-level IAM instance profiles.

### 5. Add-on Deployment: Terraform `helm_release`
- **Choice:** Automated Helm releases for AWS Load Balancer Controller and Metrics Server inside Terraform.
- **Advantages:** Complete end-to-end infrastructure provisioning in a single `terraform apply` step.
- **Trade-offs & Mitigations:** Increases initial `terraform apply` execution duration while Terraform waits for cluster deployments to reach a `Ready` state.
---

## 📁 Repository Structure

```text
├── provider.tf             # AWS and S3-Backend
├── main.tf                 # Multi-AZ VPC with public, private, and DB subnets
├── elasticache.tf          # ElastiCache Redis security group, subnet group and cluster
├── eks.tf                  # EKS cluster and Graviton Spot node groups
├── ecr.tf                  # Elastic Container Registry (ECR) to store the app image
├── iam_oidc.tf             # Passwordless OIDC authentication to push images to ECR from GitHub.
├── lbc_iam.tf              # IAM Role for Service Account (IRSA) creation for Load Balancer Controller
├── lbc_helm.tf             # AWS Load Balancer Controller Helm release
├── metrics_server_helm.tf  # Metrics Server Helm release for HPA
├── variables.tf            # Input configuration variables
└── outputs.tf              # Cluster endpoints, VPC IDs, and Redis endpoints
```
 
---

## 🛠️ Prerequisites & Local Setup

### Required Tools
Ensure you have the following tools installed on your workstation:

* **Terraform** $\ge$ 1.5.0
* **AWS CLI v2** (configured with appropriate administrator permissions)
* **kubectl** (matching the cluster version v1.34)
* **Helm** 3.x


### Environment Verification
Verify your local setup by running:

```bash
aws sts get-caller-identity
terraform version
```



## 🚀 Step-by-Step Deployment Guide
### Step 1: Initialize Terraform Workspace
Initialize the provider plugins and backend modules:

```bash
terrfaform init
```

### Step 2: Validate Configuration
Validate the syntax and consistency of all .tf files:

```bash
terrfaform validate
```
### Step 3: Review Execution Plan
Inspect the resources that Terraform will create in your AWS account:

```bash
terrfaform plan
```
### Step 4: Provision Infrastructure
Apply the execution plan to provision the VPC, EKS cluster, Redis, and Helm components:

```bash
terrfaform apply --auto-approve
```

### Step 5: Configure Local Kubernetes Context
Connect your local kubectl to the newly created EKS cluster:

```bash
aws eks update-kubeconfig --region <your-aws-region> --name <your-cluster-name>
```


### Step 6: Verify Cluster Health
Confirm that all core nodes and system deployments are active and healthy:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```
# Production EKS Infrastructure with Terraform

This repository contains production-ready Terraform infrastructure code for deploying applications on Amazon EKS (Elastic Kubernetes Service). The infrastructure includes VPC setup, security configurations, and a highly available EKS cluster with multiple node groups..

## 🏗️ Architecture Overview

The infrastructure provisions:

- **VPC**: Multi-AZ VPC with public and private subnets
- **EKS Cluster**: Production-ready Kubernetes cluster (v1.28)
- **Node Groups**: 3 specialized node groups for different workload types
- **Security Groups**: Properly configured security groups for cluster and ALB
- **IAM Roles**: Least-privilege IAM roles for EKS and node groups
- **Add-ons**: Essential EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI driver)
- **Logging**: CloudWatch logging for cluster control plane

## 📁 Project Structure

```
.
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf                    # Root module
│   ├── variables.tf               # Root variables
│   ├── outputs.tf                 # Root outputs
│   ├── versions.tf                # Provider versions
│   ├── terraform.tfvars.example   # Example variables file
│   └── modules/
│       ├── vpc/                   # VPC module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── security/              # Security groups module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── eks/                   # EKS module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI**: Configured with appropriate permissions
2. **Terraform**: Version >= 1.0
3. **kubectl**: For interacting with the EKS cluster

### AWS Permissions Required

Your AWS user/role needs the following permissions:
- EC2 (VPC, subnets, security groups, etc.)
- EKS (cluster management)
- IAM (role creation and policy attachment)
- CloudWatch Logs
- Auto Scaling

### 1. Clone the Repository

```bash
git clone https://github.com/sohaibmohd18/Terraform-AWS-EKS.git
cd Terraform-AWS-EKS
```

### 2. Set Up Backend (Optional but Recommended)

Create an S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket-name --region us-west-2

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

Update the backend configuration in `terraform/main.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket-name"
  key            = "eks-infrastructure/terraform.tfstate"
  region         = "us-west-2"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### 3. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
project_name = "my-app"
environment  = "prod"
owner        = "Your Team"
aws_region   = "us-west-2"

# Customize other variables as needed
```

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply
```

### 5. Configure kubectl

After deployment, configure kubectl to connect to your EKS cluster:

```bash
aws eks update-kubeconfig --region us-west-2 --name my-app-prod-eks
```

Verify the connection:

```bash
kubectl get nodes
```

## 🔧 Configuration Options

### Node Groups

The infrastructure creates 3 node groups by default:

1. **General**: On-demand instances for general workloads
2. **Compute**: Spot instances for compute-intensive tasks
3. **Monitoring**: Dedicated nodes for monitoring stack

You can customize node groups in `terraform.tfvars`:

```hcl
node_groups = {
  general = {
    instance_types = ["m5.medium"]
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    labels = {
      role = "general"
    }
    taints = []
  }
  # Add more node groups as needed
}
```

### EKS Add-ons

The following add-ons are installed by default:
- CoreDNS
- kube-proxy
- VPC CNI
- EBS CSI Driver

### Logging

EKS control plane logging is enabled for:
- API server
- Audit
- Authenticator
- Controller manager
- Scheduler

## 🛡️ Security Features

- **Network Isolation**: Private subnets for worker nodes
- **Security Groups**: Restrictive security group rules
- **IAM Roles**: Least-privilege access using IAM roles
- **IRSA**: IAM Roles for Service Accounts enabled
- **Encryption**: EBS volumes encrypted by default
- **Audit Logging**: Comprehensive audit logging enabled

## 📊 Monitoring and Observability

The infrastructure is designed to support comprehensive monitoring:

- **CloudWatch Integration**: Native AWS CloudWatch integration
- **Prometheus Compatible**: Ready for Prometheus deployment
- **Log Aggregation**: Supports log aggregation solutions
- **Dedicated Monitoring Nodes**: Separate node group for monitoring workloads

## 🔄 CI/CD Integration

This infrastructure supports various CI/CD patterns:

### GitHub Actions Example

```yaml
name: Deploy to EKS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --name my-app-prod-eks --region us-west-2
    
    - name: Deploy to EKS
      run: |
        kubectl apply -f k8s/
```

## 🚦 Post-Deployment Steps

### 1. Install AWS Load Balancer Controller

```bash
# Add the EKS Helm chart repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-app-prod-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2. Install Cluster Autoscaler

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

### 3. Set up Ingress

Example ingress configuration:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

## 🛠️ Maintenance

### Updating EKS Version

1. Update the `cluster_version` in `terraform.tfvars`
2. Update add-on versions to match the new EKS version
3. Apply the changes: `terraform apply`

### Scaling Node Groups

Modify the node group configuration in `terraform.tfvars` and apply:

```bash
terraform apply
```

### Backup and Disaster Recovery

- **State Files**: Terraform state is stored in S3 with versioning
- **Cluster Configuration**: All configuration is in code
- **Persistent Volumes**: Configure backup solutions for PVs

## 💰 Cost Optimization

- **Spot Instances**: Used for non-critical workloads
- **Right-sizing**: Start with smaller instances and scale as needed
- **Auto-scaling**: Cluster autoscaler reduces costs during low usage
- **Reserved Instances**: Consider RIs for production workloads

## 🐛 Troubleshooting

### Common Issues

1. **Node group creation fails**
   - Check IAM permissions
   - Verify subnet configuration
   - Ensure security groups allow communication

2. **Pods can't communicate**
   - Check VPC CNI configuration
   - Verify security group rules
   - Check route tables

3. **LoadBalancer services don't work**
   - Install AWS Load Balancer Controller
   - Check subnet tags for automatic discovery

### Useful Commands

```bash
# Check cluster status
aws eks describe-cluster --name my-app-prod-eks

# View node groups
aws eks describe-nodegroup --cluster-name my-app-prod-eks --nodegroup-name <nodegroup-name>

# Check pods
kubectl get pods -A

# View logs
kubectl logs -n kube-system deployment/coredns
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📋 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: Create an issue in this repository
- **Documentation**: Check AWS EKS documentation
- **Community**: EKS community forums

---

**Note**: This infrastructure is production-ready but should be customized based on your specific requirements. Always review and test changes in a development environment first..

---

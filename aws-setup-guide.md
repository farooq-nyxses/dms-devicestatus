# AWS Infrastructure Setup Guide

This guide will walk you through setting up the complete AWS infrastructure for your Spring Boot application.

## Prerequisites

1. **AWS Account**: You need an active AWS account
2. **AWS CLI**: Install and configure AWS CLI
3. **kubectl**: Install Kubernetes CLI
4. **eksctl**: Install eksctl for EKS management
5. **Helm**: Install Helm for package management

## Installation Instructions

### 1. AWS CLI Installation

**Windows:**
```bash
# Download and install from https://aws.amazon.com/cli/
# Or use chocolatey
choco install awscli
```

**Linux/Mac:**
```bash
# Install using pip
pip install awscli

# Or use package manager
# Ubuntu/Debian
sudo apt-get install awscli

# macOS
brew install awscli
```

**Configure AWS CLI:**
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
```

### 2. kubectl Installation

**Windows:**
```bash
# Download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Or use chocolatey
choco install kubernetes-cli
```

**Linux/Mac:**
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# macOS
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 3. eksctl Installation

**Windows:**
```bash
# Download from https://github.com/weaveworks/eksctl/releases
# Or use chocolatey
choco install eksctl
```

**Linux/Mac:**
```bash
# Linux
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# macOS
brew install eksctl
```

### 4. Helm Installation

**Windows:**
```bash
# Download from https://github.com/helm/helm/releases
# Or use chocolatey
choco install kubernetes-helm
```

**Linux/Mac:**
```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS
brew install helm
```

## Infrastructure Setup Steps

### Step 1: Create VPC and Subnets

Before running the scripts, you need to create a VPC and subnets:

1. **Go to AWS Console** > **VPC** > **Create VPC**
2. **Create VPC** with CIDR block `10.0.0.0/16`
3. **Create Subnets**:
   - Public Subnet 1: `10.0.1.0/24` in `us-east-1a`
   - Public Subnet 2: `10.0.2.0/24` in `us-east-1b`
4. **Create Internet Gateway** and attach to VPC
5. **Create Route Table** and add route `0.0.0.0/0` to Internet Gateway
6. **Create Security Group** for RDS with inbound rule for PostgreSQL (port 5432)

### Step 2: Update Configuration Files

Update the following files with your actual values:

**aws-setup/rds-setup.sh:**
```bash
VPC_SECURITY_GROUP_ID="sg-xxxxxxxxx"  # Your security group ID
```

**aws-setup/eks-setup.sh:**
```bash
VPC_ID="vpc-xxxxxxxxx"  # Your VPC ID
SUBNET_IDS="subnet-xxxxxxxxx,subnet-yyyyyyyyy"  # Your subnet IDs
```

**k8s/secret.yaml:**
```yaml
DB_URL: "jdbc:postgresql://your-rds-endpoint:5432/devicestatus"
DB_USERNAME: "your-username"
DB_PASSWORD: "your-password"
```

**k8s/deployment.yaml:**
```yaml
image: YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devicestatus-app:latest
```

**k8s/ingress.yaml:**
```yaml
host: devicestatus.yourdomain.com  # Your domain
certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID
```

### Step 3: Run Setup Scripts

Execute the scripts in the following order:

```bash
# 1. Set up RDS PostgreSQL
chmod +x aws-setup/rds-setup.sh
./aws-setup/rds-setup.sh

# 2. Set up ECR repository
chmod +x aws-setup/ecr-setup.sh
./aws-setup/ecr-setup.sh

# 3. Set up EKS cluster
chmod +x aws-setup/eks-setup.sh
./aws-setup/eks-setup.sh

# 4. Deploy to Kubernetes
chmod +x k8s/deploy.sh
./k8s/deploy.sh
```

## Cost Optimization

### RDS Optimization
- Use `db.t3.micro` for development
- Enable automated backups
- Use Multi-AZ for production
- Set up monitoring and alerts

### EKS Optimization
- Use `t3.medium` nodes for development
- Enable cluster autoscaling
- Use spot instances for non-critical workloads
- Monitor resource usage

### ECR Optimization
- Set up lifecycle policies
- Clean up unused images
- Use image scanning

## Security Best Practices

1. **IAM Roles**: Use least privilege principle
2. **Security Groups**: Restrict access to necessary ports only
3. **Encryption**: Enable encryption at rest and in transit
4. **Secrets Management**: Use AWS Secrets Manager or Kubernetes secrets
5. **Network Security**: Use private subnets for databases
6. **Monitoring**: Set up CloudWatch alarms

## Monitoring and Logging

### CloudWatch
- Set up RDS monitoring
- Configure EKS cluster monitoring
- Create custom dashboards

### Application Logs
- Use Kubernetes logging
- Integrate with ELK stack or CloudWatch Logs
- Set up log aggregation

## Troubleshooting

### Common Issues

1. **RDS Connection Issues**:
   - Check security groups
   - Verify VPC configuration
   - Check database credentials

2. **EKS Cluster Issues**:
   - Verify IAM permissions
   - Check node group status
   - Review cluster logs

3. **ECR Push Issues**:
   - Check AWS credentials
   - Verify repository permissions
   - Check region configuration

4. **Kubernetes Deployment Issues**:
   - Check pod status
   - Review application logs
   - Verify image pull secrets

### Useful Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check RDS status
aws rds describe-db-instances --db-instance-identifier devicestatus-db

# Check ECR repositories
aws ecr describe-repositories

# Check EKS clusters
aws eks list-clusters
```

## Next Steps

1. **Set up CI/CD pipeline** with Jenkins
2. **Configure monitoring** and alerting
3. **Set up backup** and disaster recovery
4. **Implement security** best practices
5. **Optimize costs** based on usage patterns

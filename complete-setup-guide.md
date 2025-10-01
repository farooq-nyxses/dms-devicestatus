# Complete DevOps Pipeline Setup Guide

This comprehensive guide will walk you through setting up a complete CI/CD pipeline for your Spring Boot application on AWS.

## Overview

Your DevOps pipeline includes:
1. **Docker Containerization** - Package your Spring Boot application
2. **Jenkins CI/CD** - Automated build, test, and deployment
3. **AWS RDS** - Managed PostgreSQL database
4. **AWS ECR** - Container registry for Docker images
5. **AWS EKS** - Kubernetes cluster for container orchestration
6. **Kubernetes Deployment** - Production-ready application deployment

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] AWS Account with appropriate permissions
- [ ] Docker Desktop installed and running
- [ ] Jenkins server (local or cloud)
- [ ] Git repository with your code
- [ ] Domain name (optional, for production)

## Step-by-Step Setup

### Phase 1: Local Development Setup

#### 1.1 Test Docker Containerization

```bash
# Build and test your Docker image locally
chmod +x docker-build.bat  # Windows
# or
chmod +x docker-build.sh   # Linux/Mac

# Run the script
./docker-build.bat  # Windows
# or
./docker-build.sh   # Linux/Mac
```

**What this does:**
- Builds your Spring Boot application into a Docker image
- Tests the container locally
- Verifies the application starts correctly

#### 1.2 Verify Application Health

```bash
# Check if your application is running
curl http://localhost:8080/actuator/health

# View application logs
docker logs devicestatus-container
```

### Phase 2: AWS Infrastructure Setup

#### 2.1 Install Required Tools

**AWS CLI:**
```bash
# Windows (using chocolatey)
choco install awscli

# Linux/Mac
pip install awscli
```

**kubectl:**
```bash
# Windows
choco install kubernetes-cli

# Linux/Mac
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**eksctl:**
```bash
# Windows
choco install eksctl

# Linux/Mac
brew install eksctl
```

**Helm:**
```bash
# Windows
choco install kubernetes-helm

# Linux/Mac
brew install helm
```

#### 2.2 Configure AWS CLI

```bash
aws configure
# Enter your Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
```

#### 2.3 Create VPC and Networking

1. **Go to AWS Console** > **VPC**
2. **Create VPC** with CIDR `10.0.0.0/16`
3. **Create Subnets**:
   - Public Subnet 1: `10.0.1.0/24` in `us-east-1a`
   - Public Subnet 2: `10.0.2.0/24` in `us-east-1b`
4. **Create Internet Gateway** and attach to VPC
5. **Create Route Table** with route `0.0.0.0/0` to Internet Gateway
6. **Create Security Group** for RDS (PostgreSQL port 5432)

#### 2.4 Set Up AWS Services

**Update configuration files with your actual values:**

1. **Update `aws-setup/rds-setup.sh`:**
   ```bash
   VPC_SECURITY_GROUP_ID="sg-xxxxxxxxx"  # Your security group ID
   ```

2. **Update `aws-setup/eks-setup.sh`:**
   ```bash
   VPC_ID="vpc-xxxxxxxxx"  # Your VPC ID
   SUBNET_IDS="subnet-xxxxxxxxx,subnet-yyyyyyyyy"  # Your subnet IDs
   ```

3. **Run setup scripts:**
   ```bash
   # Set up RDS PostgreSQL
   chmod +x aws-setup/rds-setup.sh
   ./aws-setup/rds-setup.sh

   # Set up ECR repository
   chmod +x aws-setup/ecr-setup.sh
   ./aws-setup/ecr-setup.sh

   # Set up EKS cluster
   chmod +x aws-setup/eks-setup.sh
   ./aws-setup/eks-setup.sh
   ```

### Phase 3: Jenkins Setup

#### 3.1 Install Jenkins

**Option 1: Docker (Recommended)**
```bash
# Create Jenkins data directory
mkdir -p ~/jenkins-data

# Run Jenkins in Docker
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v ~/jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

**Option 2: Local Installation**
1. Download Jenkins WAR from https://jenkins.io/download/
2. Run: `java -jar jenkins.war --httpPort=8080`

#### 3.2 Configure Jenkins

1. **Access Jenkins**: http://localhost:8080
2. **Get initial password**: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. **Install suggested plugins**
4. **Create admin user**

#### 3.3 Install Required Plugins

Go to **Manage Jenkins** > **Manage Plugins** and install:
- Pipeline
- Docker Pipeline
- AWS Steps
- Kubernetes
- JaCoCo
- Git
- Credentials Binding

#### 3.4 Set Up Credentials

Go to **Manage Jenkins** > **Manage Credentials** > **System** > **Global credentials**:

1. **GitHub Credentials** (ID: `github-farooq`)
   - Type: Username with password
   - Username: Your GitHub username
   - Password: GitHub Personal Access Token

2. **AWS Credentials** (ID: `aws-credentials`)
   - Type: AWS Credentials
   - Access Key ID: Your AWS Access Key
   - Secret Access Key: Your AWS Secret Key

3. **Database Credentials**:
   - `db-url`: Database connection string
   - `db-username`: Database username
   - `db-password`: Database password

4. **AWS Account ID** (ID: `aws-account-id`)
   - Type: Secret text
   - Secret: Your AWS Account ID

#### 3.5 Configure Tools

Go to **Manage Jenkins** > **Global Tool Configuration**:
- **Maven**: Install Maven 3.9.x
- **JDK**: Install JDK 17
- **Docker**: Ensure Docker is available in PATH

### Phase 4: Kubernetes Deployment

#### 4.1 Update Kubernetes Manifests

1. **Update `k8s/secret.yaml`:**
   ```yaml
   DB_URL: "jdbc:postgresql://your-rds-endpoint:5432/devicestatus"
   DB_USERNAME: "your-username"
   DB_PASSWORD: "your-password"
   ```

2. **Update `k8s/deployment.yaml`:**
   ```yaml
   image: YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/devicestatus-app:latest
   ```

3. **Update `k8s/ingress.yaml`:**
   ```yaml
   host: devicestatus.yourdomain.com  # Your domain
   certificate-arn: arn:aws:acm:us-east-1:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID
   ```

#### 4.2 Deploy to Kubernetes

```bash
# Deploy application
chmod +x k8s/deploy.sh
./k8s/deploy.sh
```

### Phase 5: Pipeline Integration

#### 5.1 Create Jenkins Pipeline

1. **Create New Item** > **Pipeline**
2. **Pipeline Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: Your GitHub repository
5. **Credentials**: Select `github-farooq`
6. **Script Path**: Jenkinsfile

#### 5.2 Test Pipeline

1. **Run the pipeline** manually
2. **Check each stage** for success
3. **Verify deployment** in Kubernetes

## Pipeline Flow Explanation

### 1. Checkout Stage
- Pulls code from Git repository
- Uses credentials for secure access

### 2. Build & Test Stage
- Compiles Java code with Maven
- Runs unit tests
- Generates code coverage report

### 3. Package Stage
- Creates JAR file
- Archives artifacts for later use

### 4. Docker Build Stage
- Builds Docker image using Dockerfile
- Tags image with build number

### 5. Docker Push to ECR Stage
- Logs into AWS ECR
- Pushes image to container registry
- Tags image for production use

### 6. Deploy to Kubernetes Stage
- Updates Kubernetes deployment
- Waits for rollout completion
- Verifies deployment success

### 7. Health Check Stage
- Checks application health
- Verifies service endpoints
- Logs application status

## Monitoring and Troubleshooting

### Application Monitoring

```bash
# Check pod status
kubectl get pods -n devicestatus

# View application logs
kubectl logs -n devicestatus -l app=devicestatus-app

# Check service status
kubectl get services -n devicestatus

# Check ingress status
kubectl get ingress -n devicestatus
```

### Common Issues and Solutions

1. **Docker Build Fails**:
   - Check Dockerfile syntax
   - Verify Maven dependencies
   - Check Docker daemon status

2. **ECR Push Fails**:
   - Verify AWS credentials
   - Check ECR repository permissions
   - Ensure correct region

3. **Kubernetes Deployment Fails**:
   - Check image pull secrets
   - Verify resource limits
   - Check pod logs for errors

4. **Database Connection Issues**:
   - Verify RDS security groups
   - Check database credentials
   - Ensure VPC connectivity

## Security Best Practices

1. **Use IAM Roles**: Assign minimal required permissions
2. **Secure Secrets**: Store sensitive data in Kubernetes secrets
3. **Network Security**: Use private subnets for databases
4. **Image Scanning**: Enable ECR image scanning
5. **Regular Updates**: Keep dependencies updated

## Cost Optimization

1. **Use Spot Instances**: For non-critical workloads
2. **Right-size Resources**: Monitor and adjust resource limits
3. **Clean Up Resources**: Remove unused images and resources
4. **Set Up Alerts**: Monitor costs and usage

## Next Steps

1. **Set up monitoring** with CloudWatch
2. **Implement backup** strategies
3. **Set up disaster recovery**
4. **Optimize performance**
5. **Scale based on demand**

## Support and Resources

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Docker Documentation**: https://docs.docker.com/

## Conclusion

You now have a complete DevOps pipeline that:
- Automatically builds and tests your application
- Containerizes your Spring Boot application
- Deploys to AWS infrastructure
- Provides monitoring and health checks
- Follows security best practices

This pipeline will help you deliver software faster, more reliably, and with better quality.

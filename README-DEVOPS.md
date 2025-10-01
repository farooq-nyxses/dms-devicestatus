# DeviceStatus Application - DevOps Pipeline

This repository contains a complete DevOps pipeline for the DeviceStatus Spring Boot application, including Docker containerization, Jenkins CI/CD, and AWS deployment.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │     Jenkins     │    │      AWS       │
│                 │    │                 │    │                 │
│ 1. Code Commit  │───▶│ 2. Build & Test │───▶│ 3. Deploy      │
│                 │    │                 │    │                 │
│                 │    │ 4. Docker Build │───▶│ 5. ECR Push     │
│                 │    │                 │    │                 │
│                 │    │ 6. K8s Deploy   │───▶│ 7. EKS Cluster  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                               ┌─────────────────┐
                                               │   Production    │
                                               │                 │
                                               │ • RDS Database  │
                                               │ • Load Balancer │
                                               │ • Auto Scaling  │
                                               └─────────────────┘
```

## 📁 Project Structure

```
dms-devicestatus/
├── src/                          # Spring Boot application source
├── Dockerfile                    # Docker containerization
├── .dockerignore                 # Docker build optimization
├── Jenkinsfile                   # Jenkins CI/CD pipeline
├── pom.xml                       # Maven configuration
├── docker-build.sh/.bat          # Local Docker testing
├── jenkins-setup.md              # Jenkins installation guide
├── aws-setup/                    # AWS infrastructure scripts
│   ├── rds-setup.sh             # RDS PostgreSQL setup
│   ├── ecr-setup.sh             # ECR container registry setup
│   └── eks-setup.sh             # EKS Kubernetes cluster setup
├── k8s/                          # Kubernetes deployment manifests
│   ├── namespace.yaml           # Kubernetes namespace
│   ├── configmap.yaml           # Application configuration
│   ├── secret.yaml              # Database credentials
│   ├── deployment.yaml          # Application deployment
│   ├── service.yaml             # Kubernetes service
│   ├── ingress.yaml             # Load balancer configuration
│   └── deploy.sh                # Deployment script
├── aws-setup-guide.md           # AWS infrastructure guide
└── complete-setup-guide.md      # Complete setup instructions
```

## 🚀 Quick Start

### Prerequisites
- AWS Account with appropriate permissions
- Docker Desktop
- Jenkins server
- Git repository

### 1. Local Development
```bash
# Test Docker containerization
./docker-build.sh  # Linux/Mac
# or
./docker-build.bat # Windows

# Verify application
curl http://localhost:8080/actuator/health
```

### 2. AWS Infrastructure Setup
```bash
# Configure AWS CLI
aws configure

# Set up RDS PostgreSQL
./aws-setup/rds-setup.sh

# Set up ECR repository
./aws-setup/ecr-setup.sh

# Set up EKS cluster
./aws-setup/eks-setup.sh
```

### 3. Kubernetes Deployment
```bash
# Update configuration files with your values
# Deploy to Kubernetes
./k8s/deploy.sh
```

### 4. Jenkins Pipeline
1. Install Jenkins and required plugins
2. Configure credentials (GitHub, AWS, Database)
3. Create pipeline from Jenkinsfile
4. Run pipeline to deploy application

## 🔧 Configuration

### Environment Variables
- `DB_URL`: Database connection string
- `DB_USERNAME`: Database username
- `DB_PASSWORD`: Database password
- `SPRING_PROFILES_ACTIVE`: Spring profile (prod)

### AWS Configuration
- Region: `us-east-1`
- ECR Repository: `devicestatus-app`
- EKS Cluster: `devicestatus-cluster`
- RDS Instance: `devicestatus-db`

## 📊 Pipeline Stages

1. **Checkout**: Pull code from Git repository
2. **Build & Test**: Compile and run tests with coverage
3. **Package**: Create JAR file
4. **Docker Build**: Build Docker image
5. **Docker Push to ECR**: Push image to AWS ECR
6. **Deploy to Kubernetes**: Update K8s deployment
7. **Health Check**: Verify deployment success

## 🛠️ Technologies Used

- **Spring Boot 3.3.3**: Java application framework
- **PostgreSQL**: Database
- **Docker**: Containerization
- **Jenkins**: CI/CD pipeline
- **AWS RDS**: Managed database
- **AWS ECR**: Container registry
- **AWS EKS**: Kubernetes cluster
- **Kubernetes**: Container orchestration
- **Maven**: Build tool
- **JaCoCo**: Code coverage

## 🔒 Security Features

- Non-root user in Docker containers
- Encrypted RDS database
- IAM roles with least privilege
- Kubernetes secrets for sensitive data
- Security groups for network access
- Image scanning in ECR

## 📈 Monitoring

- Application health checks
- Kubernetes pod monitoring
- AWS CloudWatch integration
- Jenkins build notifications
- Database performance monitoring

## 💰 Cost Optimization

- Multi-stage Docker builds
- ECR lifecycle policies
- EKS cluster autoscaling
- RDS automated backups
- Resource limits and requests

## 🚨 Troubleshooting

### Common Issues
1. **Docker Build Fails**: Check Dockerfile syntax and dependencies
2. **ECR Push Fails**: Verify AWS credentials and permissions
3. **K8s Deployment Fails**: Check image pull secrets and resource limits
4. **Database Connection Issues**: Verify RDS security groups and credentials

### Useful Commands
```bash
# Check pod status
kubectl get pods -n devicestatus

# View application logs
kubectl logs -n devicestatus -l app=devicestatus-app

# Check service status
kubectl get services -n devicestatus

# Scale deployment
kubectl scale deployment devicestatus-app --replicas=3 -n devicestatus
```

## 📚 Documentation

- [Jenkins Setup Guide](jenkins-setup.md)
- [AWS Infrastructure Guide](aws-setup-guide.md)
- [Complete Setup Guide](complete-setup-guide.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the pipeline
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the documentation
3. Create an issue in the repository
4. Contact the development team

---

**Happy Deploying! 🚀**

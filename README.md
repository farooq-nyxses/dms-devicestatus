# DeviceStatus Application - AWS DevOps Pipeline

A complete Spring Boot application with automated CI/CD pipeline deployed on AWS using Docker, Jenkins, and Kubernetes.

## 🚀 Live Application

**Application URL**: http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com

**API Endpoints**:
- Device Statuses: `/devicestatuses`
- Health Check: `/actuator/health`
- Application Info: `/actuator/info`

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │     Jenkins     │    │      AWS       │
│                 │    │                 │    │                 │
│  Spring Boot    │───▶│  CI/CD Pipeline │───▶│  EKS Cluster   │
│  Application    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Docker Hub    │    │   AWS RDS       │
                       │   (ECR)         │    │   PostgreSQL    │
                       └─────────────────┘    └─────────────────┘
```

## 🛠️ Technology Stack

- **Backend**: Spring Boot 3.3.3, Java 17
- **Database**: PostgreSQL (AWS RDS)
- **Containerization**: Docker
- **CI/CD**: Jenkins
- **Orchestration**: Kubernetes (AWS EKS)
- **Cloud Provider**: AWS
- **Container Registry**: AWS ECR

## 📋 Prerequisites

- Java 17+
- Maven 3.9.x
- Docker Desktop
- Jenkins
- AWS CLI
- kubectl
- eksctl

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/farooq-nyxses/dms-devicestatus.git
cd dms-devicestatus
```

### 2. Local Development
```bash
# Run with local PostgreSQL
mvn spring-boot:run -Dspring-boot.run.profiles=local

# Or run with H2 database
mvn spring-boot:run -Dspring-boot.run.profiles=h2
```

### 3. Docker Build
```bash
docker build -t devicestatus-app:latest .
docker run -p 8080:8080 devicestatus-app:latest
```

## 🔧 AWS Infrastructure

### Deployed Resources
- **VPC**: Custom VPC with public/private subnets
- **RDS**: PostgreSQL database (`devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com`)
- **ECR**: Container registry (`128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app`)
- **EKS**: Kubernetes cluster (`devicestatus-cluster`)
- **LoadBalancer**: Application Load Balancer

### Resource Details
- **Region**: ap-south-1 (Mumbai)
- **EC2 Instances**: 2x t3.small (worker nodes)
- **Kubernetes Pods**: 2 replicas
- **Database**: PostgreSQL 16.3

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Stages
1. **Checkout** - Git repository clone
2. **Build & Test** - Maven build and testing
3. **Package** - Spring Boot JAR creation
4. **Docker Build** - Container image creation
5. **Docker Push** - Push to AWS ECR
6. **Configure kubectl** - EKS cluster connection
7. **Deploy to Kubernetes** - Rolling deployment
8. **Health Check** - Application verification

### Pipeline Configuration
- **Repository**: https://github.com/farooq-nyxses/dms-devicestatus.git
- **Branch**: dev-aws-branch
- **Build Trigger**: Manual or webhook
- **Artifacts**: Spring Boot JAR files

## 📁 Project Structure

```
dms-devicestatus/
├── src/main/java/com/example/devicestatus/
│   ├── DeviceStatusApplication.java
│   ├── model/DeviceStatus.java
│   ├── repo/DeviceStatusRepository.java
│   └── web/DeviceStatusController.java
├── src/main/resources/
│   ├── application-local.properties
│   ├── application-dev.properties
│   └── application-prod.properties
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── ingress-custom-domain.yaml
├── aws-setup/
│   ├── vpc-setup.bat
│   ├── rds-setup.bat
│   ├── ecr-setup.bat
│   ├── eks-setup.bat
│   └── aws-resources.txt
├── Dockerfile
├── Jenkinsfile
├── pom.xml
└── README.md
```

## 🔐 Configuration

### Environment Variables
- `SPRING_PROFILES_ACTIVE`: prod
- `DB_URL`: jdbc:postgresql://devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com:5432/devicestatus
- `DB_USERNAME`: devicestatus
- `DB_PASSWORD`: DevStatus2024!

### Kubernetes Resources
- **Namespace**: devicestatus
- **Deployment**: devicestatus-app (2 replicas)
- **Service**: devicestatus-service (LoadBalancer)
- **ConfigMap**: devicestatus-config
- **Secret**: devicestatus-secret

## 📊 Monitoring & Health Checks

### Health Endpoints
- **Liveness Probe**: `/actuator/health` (every 30s)
- **Readiness Probe**: `/actuator/health` (every 10s)
- **Metrics**: `/actuator/metrics`

### Resource Limits
- **CPU Request**: 250m
- **CPU Limit**: 500m
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi

## 🚀 Deployment Commands

### Kubernetes Commands
```bash
# Check pods
kubectl get pods -n devicestatus

# Check services
kubectl get services -n devicestatus

# View logs
kubectl logs -n devicestatus -l app=devicestatus-app

# Scale deployment
kubectl scale deployment devicestatus-app --replicas=3 -n devicestatus
```

### AWS Commands
```bash
# Check EKS cluster
aws eks describe-cluster --name devicestatus-cluster --region ap-south-1

# Check ECR images
aws ecr describe-images --repository-name devicestatus-app --region ap-south-1

# Check RDS instance
aws rds describe-db-instances --db-instance-identifier devicestatus-db --region ap-south-1
```

## 🔧 Troubleshooting

### Common Issues
1. **Pod not starting**: Check logs with `kubectl logs -n devicestatus -l app=devicestatus-app`
2. **Database connection**: Verify RDS security groups and credentials
3. **LoadBalancer not accessible**: Check AWS LoadBalancer status
4. **Pipeline failures**: Check Jenkins console output

### Useful Commands
```bash
# Port forward for local testing
kubectl port-forward -n devicestatus service/devicestatus-service 8080:80

# Check deployment status
kubectl rollout status deployment/devicestatus-app -n devicestatus

# Restart deployment
kubectl rollout restart deployment/devicestatus-app -n devicestatus
```

## 📈 Performance & Scaling

### Current Configuration
- **Pods**: 2 replicas
- **Instance Type**: t3.small (2 vCPUs, 2 GB RAM)
- **Auto-scaling**: Available (configure HPA)

### Scaling Options
```bash
# Horizontal Pod Autoscaler
kubectl autoscale deployment devicestatus-app --cpu-percent=70 --min=2 --max=10 -n devicestatus

# Vertical scaling (update deployment.yaml)
# Change resource requests/limits
```

## 💰 Cost Estimation

### Monthly AWS Costs
- **EKS Control Plane**: ~$73
- **EC2 Instances (2x t3.small)**: ~$30
- **RDS (db.t3.micro)**: ~$15
- **LoadBalancer**: ~$18
- **ECR**: ~$1
- **Total**: ~$137/month

## 🔒 Security

### Implemented Security Measures
- **Non-root containers**: Spring user in Docker
- **Network isolation**: Private subnets for RDS
- **Secrets management**: Kubernetes secrets
- **Resource limits**: CPU and memory constraints
- **Health checks**: Liveness and readiness probes

## 📞 Support

For issues or questions:
1. Check Jenkins pipeline logs
2. Review Kubernetes pod logs
3. Verify AWS resource status
4. Check this README for troubleshooting steps

## 🎯 Next Steps

### Potential Improvements
1. **Custom Domain**: Set up Route 53 with custom domain
2. **SSL Certificate**: Enable HTTPS with ACM certificate
3. **Monitoring**: Add Prometheus and Grafana
4. **Logging**: Implement centralized logging with ELK stack
5. **Backup**: Set up automated database backups
6. **Multi-environment**: Add staging and production environments

---

**Last Updated**: October 2025  
**Status**: ✅ Production Ready  
**Version**: 1.0.0
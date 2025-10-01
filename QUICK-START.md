# DeviceStatus Application - Quick Start Guide

## 🚀 Your Application is Live!

**Application URL**: http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com

---

## 🌐 Test Your Application Now

### From Browser

Simply open these URLs in your web browser:

1. **Get All Device Statuses**:
   ```
   http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses
   ```

2. **Health Check**:
   ```
   http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/actuator/health
   ```

### From Command Line (PowerShell)

```powershell
# Get all device statuses
Invoke-WebRequest -Uri "http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses" -UseBasicParsing | Select-Object -ExpandProperty Content

# Health check
Invoke-WebRequest -Uri "http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/actuator/health" -UseBasicParsing | Select-Object -ExpandProperty Content

# Get single device status (deviceId = 1)
Invoke-WebRequest -Uri "http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses/1" -UseBasicParsing | Select-Object -ExpandProperty Content
```

---

## 📋 What's Deployed

### Infrastructure
- ✅ **AWS VPC**: Custom networking (vpc-09e1e69e062ace054)
- ✅ **AWS EKS**: Kubernetes cluster (devicestatus-cluster)
- ✅ **AWS RDS**: PostgreSQL database (devicestatus-db)
- ✅ **AWS ECR**: Docker image registry
- ✅ **AWS ELB**: Load balancer for public access
- ✅ **2 Application Pods**: Running Spring Boot application

### Application
- ✅ Spring Boot 3.3.3
- ✅ Java 17
- ✅ PostgreSQL 16.3
- ✅ 2 replicas for high availability
- ✅ Auto-healing with health checks
- ✅ Load balanced traffic

---

## 🎯 Next Steps

### 1. Set Up Jenkins (Optional but Recommended)

**Follow the detailed guide**: `JENKINS-SETUP-GUIDE.md`

**Quick Steps**:
1. Download Jenkins from https://www.jenkins.io/download/
2. Install Jenkins
3. Access at http://localhost:8080
4. Install required plugins
5. Set up credentials
6. Create pipeline job
7. Configure GitHub webhook

### 2. Connect to Database (Optional)

**Using DBeaver or pgAdmin**:
- **Host**: devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com
- **Port**: 5432
- **Database**: devicestatus
- **Username**: devicestatus
- **Password**: DevStatus2024!

### 3. Monitor Application

```powershell
# Check pods
kubectl get pods -n devicestatus

# Check services
kubectl get svc -n devicestatus

# View logs
kubectl logs -n devicestatus -l app=devicestatus-app

# Follow logs
kubectl logs -n devicestatus -l app=devicestatus-app -f
```

---

## 📚 Documentation

### Complete Guides Available
- **JENKINS-SETUP-GUIDE.md**: Step-by-step Jenkins installation and configuration
- **jenkins-commands.md**: Quick reference for common commands
- **DEPLOYMENT-SUMMARY.md**: Complete deployment details and architecture
- **QUICK-START.md**: This guide

### Key Commands Reference

#### Check Application Status
```powershell
# Get all resources in devicestatus namespace
kubectl get all -n devicestatus

# Describe service
kubectl describe svc devicestatus-service -n devicestatus

# Get LoadBalancer URL
kubectl get svc devicestatus-service -n devicestatus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

#### Update Application
```powershell
# Build new image
docker build -t devicestatus-app:v2 .

# Tag for ECR
docker tag devicestatus-app:v2 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:v2

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 128121110035.dkr.ecr.ap-south-1.amazonaws.com

# Push to ECR
docker push 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:v2

# Update Kubernetes deployment
kubectl set image deployment/devicestatus-app devicestatus-app=128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:v2 -n devicestatus

# Watch rollout
kubectl rollout status deployment/devicestatus-app -n devicestatus
```

#### Rollback Deployment
```powershell
# View rollout history
kubectl rollout history deployment/devicestatus-app -n devicestatus

# Rollback to previous version
kubectl rollout undo deployment/devicestatus-app -n devicestatus

# Rollback to specific revision
kubectl rollout undo deployment/devicestatus-app -n devicestatus --to-revision=2
```

---

## 🔧 Troubleshooting

### Application Not Responding

**Check pod status**:
```powershell
kubectl get pods -n devicestatus
```

**View logs**:
```powershell
kubectl logs -n devicestatus -l app=devicestatus-app --tail=100
```

**Restart pods**:
```powershell
kubectl rollout restart deployment/devicestatus-app -n devicestatus
```

### Database Connection Issues

**Test from pod**:
```powershell
kubectl exec -it -n devicestatus deployment/devicestatus-app -- sh
# Inside pod:
nc -zv devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com 5432
```

### Jenkins Pipeline Failures

1. Check Jenkins console output
2. Verify AWS credentials are configured
3. Ensure kubectl is configured correctly
4. Check Docker is running

---

## 💡 Tips & Best Practices

### Security
- ⚠️ Remove `0.0.0.0/0` from RDS security group after testing
- 🔐 Use secrets for sensitive data, never commit passwords
- 🔒 Consider enabling HTTPS with SSL/TLS certificate
- 👤 Use IAM roles instead of access keys when possible

### Performance
- 📊 Monitor CloudWatch metrics
- 🔍 Review application logs regularly
- ⚡ Consider caching for frequently accessed data
- 📈 Enable auto-scaling based on metrics

### Cost Optimization
- 💰 Use t3.micro or t3.small instances for development
- 📉 Scale down non-production environments
- 🕐 Schedule start/stop for dev/test environments
- 🗑️ Clean up old Docker images from ECR

### Development Workflow
1. Develop locally
2. Test with Docker container
3. Commit and push to GitHub
4. Jenkins automatically builds and deploys
5. Verify in Kubernetes
6. Monitor logs and metrics

---

## 📊 System Architecture

```
Developer → GitHub → Jenkins → Docker → ECR → Kubernetes (EKS) → LoadBalancer → Users
                                                    ↓
                                              RDS PostgreSQL
```

---

## 🆘 Getting Help

### Documentation
- Review complete guides in project root
- Check AWS documentation: https://docs.aws.amazon.com/
- Check Kubernetes docs: https://kubernetes.io/docs/
- Check Spring Boot docs: https://spring.io/projects/spring-boot

### Common Resources
- AWS Account ID: 128121110035
- AWS Region: ap-south-1
- EKS Cluster: devicestatus-cluster
- Namespace: devicestatus
- ECR Repository: devicestatus-app

---

## ✅ Deployment Checklist

- [x] Application containerized with Docker
- [x] Docker image pushed to AWS ECR
- [x] Kubernetes cluster deployed on AWS EKS
- [x] Application deployed to Kubernetes
- [x] Database configured on AWS RDS
- [x] LoadBalancer configured for public access
- [x] Application accessible from internet
- [x] Health checks configured
- [x] Jenkinsfile created for CI/CD
- [ ] Jenkins server set up (next step)
- [ ] GitHub webhook configured (after Jenkins)
- [ ] Monitoring and alerting configured (optional)
- [ ] SSL/TLS certificate configured (optional)

---

## 🎉 Success!

Your Spring Boot application is now:
- ✅ Running on AWS
- ✅ Highly available (2 replicas)
- ✅ Auto-healing
- ✅ Load balanced
- ✅ Connected to managed database
- ✅ Ready for CI/CD

**Application URL**: 
```
http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses
```

**Go ahead and test it now!** 🚀

---

**Questions?** Review the comprehensive guides in the project documentation.

**Ready for Jenkins?** Follow `JENKINS-SETUP-GUIDE.md` for complete CI/CD automation.


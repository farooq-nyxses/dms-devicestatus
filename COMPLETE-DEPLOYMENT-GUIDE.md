# Complete DevOps Pipeline Guide: Spring Boot to AWS Kubernetes

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Docker Configuration](#docker-configuration)
4. [AWS Infrastructure Setup](#aws-infrastructure-setup)
5. [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
6. [Kubernetes Deployment](#kubernetes-deployment)
7. [Testing and Validation](#testing-and-validation)
8. [Troubleshooting](#troubleshooting)
9. [Demo Script](#demo-script)

---

## Prerequisites

### Required Software
- **Java 17** (OpenJDK or Oracle JDK)
- **Maven 3.9+**
- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **AWS CLI 2.x**
- **kubectl** (Kubernetes CLI)
- **eksctl** (EKS CLI)
- **Jenkins** (LTS version)
- **Git**

### AWS Account Requirements
- AWS Account with appropriate permissions
- Access Key ID and Secret Access Key
- Region: `ap-south-1` (Mumbai)

### GitHub Repository
- Repository: `https://github.com/farooq-nyxses/dms-devicestatus.git`
- Branch: `dev-aws-branch`

---

## Project Setup

### 1. Clone Repository
```bash
git clone https://github.com/farooq-nyxses/dms-devicestatus.git
cd dms-devicestatus
git checkout dev-aws-branch
```

### 2. Verify Project Structure
```
dms-devicestatus/
├── src/
│   └── main/
│       ├── java/com/example/devicestatus/
│       │   ├── DeviceStatusApplication.java
│       │   ├── model/DeviceStatus.java
│       │   ├── repo/DeviceStatusRepository.java
│       │   └── web/DeviceStatusController.java
│       └── resources/
│           ├── application-dev.properties
│           ├── application-local.properties
│           └── application-prod.properties
├── pom.xml
└── Dockerfile
```

### 3. Update pom.xml (Add Required Dependencies)
```xml
<dependencies>
    <!-- Existing dependencies -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>

<plugins>
    <!-- Existing plugins -->
    <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.8.11</version>
        <executions>
            <execution>
                <goals>
                    <goal>prepare-agent</goal>
                </goals>
            </execution>
            <execution>
                <id>report</id>
                <phase>test</phase>
                <goals>
                    <goal>report</goal>
                </goals>
            </execution>
        </executions>
    </plugin>
</plugins>
```

---

## Docker Configuration

### 1. Create Dockerfile
```dockerfile
# Multi-stage build for Spring Boot application
# Stage 1: Build stage
FROM maven:latest AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies to leverage Docker layer caching
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package spring-boot:repackage -DskipTests

# Stage 2: Runtime stage
FROM openjdk:17

# Create non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy the JAR file from builder stage
COPY --from=builder /app/target/devicestatus-app-*.jar app.jar

# Change ownership to non-root user
RUN chown spring:spring app.jar

# Switch to non-root user
USER spring

# Expose the port the application runs on
EXPOSE 8080

# Define health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD curl --fail http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 2. Create .dockerignore
```
target/
.git/
.gitignore
README.md
Dockerfile
.dockerignore
node_modules/
npm-debug.log
```

### 3. Test Docker Build Locally
```bash
# Build Docker image
docker build -t devicestatus-app:latest .

# Run container locally (for testing)
docker run -d -p 8080:8080 --name devicestatus-container devicestatus-app:latest

# Test application
curl http://localhost:8080/devicestatuses

# Stop and remove container
docker stop devicestatus-container
docker rm devicestatus-container
```

---

## AWS Infrastructure Setup

### 1. Configure AWS CLI
```bash
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: ap-south-1
# Default output format: json
```

### 2. Create VPC and Networking
```bash
# Run VPC setup script
cd aws-setup
./vpc-setup.bat  # Windows
# or
./vpc-setup.sh   # Linux/Mac
```

**Expected Output:**
```
✅ VPC ID: vpc-07df9e2e6c8d5e53a
✅ Public Subnet 1: subnet-0df52455210c6dafe
✅ Public Subnet 2: subnet-0af87507b9cb34eeb
✅ Private Subnet 1: subnet-020836158ae5f0223
✅ Private Subnet 2: subnet-0ca89ec1b6c95e4f7
✅ Security Group: sg-0e61d08458676e46a
```

### 3. Deploy RDS PostgreSQL Database
```bash
# Run RDS setup script
./rds-setup.bat  # Windows
# or
./rds-setup.sh   # Linux/Mac
```

**Important Notes:**
- Use PostgreSQL version `16.3` (not 15.4)
- Database will take 5-10 minutes to create
- Note the endpoint for later use

**Expected Output:**
```
✅ Database Information:
   Instance ID: devicestatus-db
   Endpoint: devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com
   Port: 5432
   Database Name: devicestatus
   Username: devicestatus
   Password: DevStatus2024!
```

### 4. Set Up ECR Container Registry
```bash
# Run ECR setup script
./ecr-setup.bat  # Windows
# or
./ecr-setup.sh   # Linux/Mac
```

**Expected Output:**
```
✅ Repository Information:
   Repository Name: devicestatus-app
   Repository URI: 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app
   Region: ap-south-1
```

### 5. Deploy EKS Kubernetes Cluster
```bash
# Install eksctl first (if not installed)
# Windows: Download from https://eksctl.io/introduction/#installation
# Linux: curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin

# Run EKS setup script
./eks-setup-fixed.bat  # Windows
# or
./eks-setup-fixed.sh   # Linux/Mac
```

**Important Notes:**
- Cluster creation takes 15-20 minutes
- Use `t3.small` instance type (not t3.medium)
- Remove `--ssh-access` flag to avoid key pair issues

**Expected Output:**
```
✅ Cluster Information:
   Cluster Name: devicestatus-cluster
   Region: ap-south-1
   Node Group: devicestatus-nodes
   Node Type: t3.small
   Node Count: 2
```

---

## Jenkins Pipeline Configuration

### 1. Install Jenkins
**Windows:**
- Download Jenkins LTS from https://jenkins.io/download/
- Run installer and follow setup wizard
- Install suggested plugins

**Linux:**
```bash
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo apt-key add -
echo "deb https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update
sudo apt-get install jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 2. Configure Jenkins Plugins
Install these plugins:
- **Git Plugin**
- **Pipeline Plugin**
- **Docker Pipeline Plugin**
- **AWS Steps Plugin**
- **Kubernetes CLI Plugin**

### 3. Configure Jenkins Credentials
Add these credentials in Jenkins:

1. **GitHub Credentials**
   - ID: `github-farooq-nyxses`
   - Type: Username with password
   - Username: `farooq-nyxses`
   - Password: `[GitHub Personal Access Token]`

2. **AWS Credentials**
   - ID: `aws-access-key`
   - Type: Secret text
   - Secret: `[Your AWS Access Key ID]`
   
   - ID: `aws-secret-key`
   - Type: Secret text
   - Secret: `[Your AWS Secret Access Key]`

3. **Database Password**
   - ID: `db-password`
   - Type: Secret text
   - Secret: `DevStatus2024!`

### 4. Create Jenkinsfile
```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven_3.9.x'
    }
    
    environment {
        // Git Configuration
        REPO_URL   = 'https://github.com/farooq-nyxses/dms-devicestatus.git'
        BRANCH     = 'dev-aws-branch'
        CRED_ID    = 'github-farooq-nyxses'
        
        // AWS Configuration
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '128121110035'
        ECR_REPOSITORY = 'devicestatus-app'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        EKS_CLUSTER_NAME = 'devicestatus-cluster'
        
        // AWS Credentials (using Jenkins credentials)
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        
        // Application Configuration
        APP_NAME = 'devicestatus-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBE_NAMESPACE = 'devicestatus'
        
        // Database Configuration
        DB_URL = 'jdbc:postgresql://devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com:5432/devicestatus'
        DB_USERNAME = 'devicestatus'
        DB_PASSWORD = credentials('db-password')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm: [
                    $class: 'GitSCM',
                    branches: [[name: "*/${BRANCH}"]],
                    userRemoteConfigs: [[
                        url: "${REPO_URL}",
                        credentialsId: "${CRED_ID}"
                    ]]
                ]
            }
        }
        
        stage('Build') {
            steps {
                bat 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                bat 'mvn test'
            }
        }
        
        stage('Package') {
            steps {
                bat 'mvn clean package spring-boot:repackage -DskipTests'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    // Build Docker image
                    bat "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
                    bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest"
                }
            }
        }
        
        stage('Docker Push to ECR') {
            steps {
                script {
                    // Login to ECR
                    bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    
                    // Tag image for ECR
                    bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                    bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                    
                    // Push to ECR
                    bat "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                    bat "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
                }
            }
        }
        
        stage('Configure kubectl') {
            steps {
                script {
                    // Configure kubectl to use EKS cluster
                    bat """
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        kubectl config current-context
                    """
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Apply Kubernetes manifests
                    bat "kubectl apply -f k8s/"
                    
                    // Wait for deployment to be ready
                    bat "kubectl rollout status deployment/devicestatus-app -n ${KUBE_NAMESPACE} --timeout=300s"
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    // Get service endpoint
                    bat """
                        kubectl get service devicestatus-service -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                    """
                    
                    // Health check
                    bat """
                        timeout 30
                        kubectl get pods -n ${KUBE_NAMESPACE} -l app=${APP_NAME}
                        kubectl logs -n ${KUBE_NAMESPACE} -l app=${APP_NAME} --tail=50
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images
            bat "docker rmi ${APP_NAME}:${IMAGE_TAG} || true"
            bat "docker rmi ${APP_NAME}:latest || true"
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### 5. Create Jenkins Pipeline Job
1. Go to Jenkins Dashboard
2. Click "New Item"
3. Enter name: `devicestatus-pipeline`
4. Select "Pipeline"
5. Click "OK"
6. In Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/farooq-nyxses/dms-devicestatus.git`
   - Credentials: `github-farooq-nyxses`
   - Branch Specifier: `dev-aws-branch`
   - Script Path: `Jenkinsfile`
7. Click "Save"
8. Click "Build Now"

---

## Kubernetes Deployment

### 1. Create Kubernetes Manifests

**k8s/namespace.yaml**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: devicestatus
  labels:
    name: devicestatus
```

**k8s/configmap.yaml**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: devicestatus-config
  namespace: devicestatus
data:
  SPRING_PROFILES_ACTIVE: "prod"
  SERVER_PORT: "8080"
  DDL_AUTO: "validate"
```

**k8s/secret.yaml**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: devicestatus-secret
  namespace: devicestatus
type: Opaque
stringData:
  # These will be automatically base64 encoded
  DB_URL: "jdbc:postgresql://devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com:5432/devicestatus"
  DB_USERNAME: "devicestatus"
  DB_PASSWORD: "DevStatus2024!"
```

**k8s/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devicestatus-app
  namespace: devicestatus
  labels:
    app: devicestatus-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devicestatus-app
  template:
    metadata:
      labels:
        app: devicestatus-app
    spec:
      containers:
      - name: devicestatus-app
        image: 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          valueFrom:
            configMapKeyRef:
              name: devicestatus-config
              key: SPRING_PROFILES_ACTIVE
        - name: SERVER_PORT
          valueFrom:
            configMapKeyRef:
              name: devicestatus-config
              key: SERVER_PORT
        - name: DDL_AUTO
          valueFrom:
            configMapKeyRef:
              name: devicestatus-config
              key: DDL_AUTO
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: devicestatus-secret
              key: DB_URL
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: devicestatus-secret
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: devicestatus-secret
              key: DB_PASSWORD
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

**k8s/service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: devicestatus-service
  namespace: devicestatus
  labels:
    app: devicestatus-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: devicestatus-app
```

**k8s/ingress.yaml**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devicestatus-ingress
  namespace: devicestatus
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '30'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '3'
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-south-1:128121110035:certificate/YOUR_CERTIFICATE_ID
spec:
  rules:
  - host: devicestatus.yourdomain.com  # Replace with your domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: devicestatus-service
            port:
              number: 80
```

### 2. Deploy to Kubernetes
```bash
# Apply all manifests
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -n devicestatus
kubectl get services -n devicestatus
kubectl get ingress -n devicestatus
```

---

## Testing and Validation

### 1. Verify Application Deployment
```bash
# Check pod status
kubectl get pods -n devicestatus

# Check service
kubectl get service devicestatus-service -n devicestatus

# Get LoadBalancer endpoint
kubectl get service devicestatus-service -n devicestatus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 2. Test Application Endpoints
```bash
# Get the LoadBalancer URL
LOADBALANCER_URL=$(kubectl get service devicestatus-service -n devicestatus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$LOADBALANCER_URL/actuator/health

# Test application endpoint
curl http://$LOADBALANCER_URL/devicestatuses
```

### 3. Monitor Application Logs
```bash
# View pod logs
kubectl logs -n devicestatus -l app=devicestatus-app --tail=50

# Follow logs in real-time
kubectl logs -n devicestatus -l app=devicestatus-app -f
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Docker Build Issues
**Problem**: `maven:3.9.6-openjdk-17-slim: not found`
**Solution**: Use `maven:latest` and `openjdk:17` in Dockerfile

**Problem**: `no main manifest attribute, in app.jar`
**Solution**: Use `mvn clean package spring-boot:repackage -DskipTests`

#### 2. AWS CLI Issues
**Problem**: `aws: command not found`
**Solution**: Use full path: `E:\Amazon\AWSCLIV2\aws.exe` (Windows)

#### 3. RDS Connection Issues
**Problem**: `Connection refused` to RDS
**Solution**: 
- Check security group allows port 5432
- Verify RDS endpoint is correct
- Ensure RDS is in "available" state

#### 4. EKS Cluster Issues
**Problem**: `Duplicate key(s) in resource tags: [Name]`
**Solution**: Remove `--ssh-access` flag and use different tag names

**Problem**: `Could not launch On-Demand Instances`
**Solution**: Use `t3.small` instead of `t3.medium`

#### 5. Jenkins Pipeline Issues
**Problem**: `fatal: couldn't find remote ref refs/heads/master`
**Solution**: Use correct branch name: `dev-aws-branch`

**Problem**: `No such DSL method 'publishTestResults' found`
**Solution**: Remove unsupported pipeline steps

**Problem**: `Unable to locate credentials`
**Solution**: Add AWS credentials in Jenkins with correct IDs

#### 6. Kubernetes Deployment Issues
**Problem**: `Error from server (NotFound): services "devicestatus-app-service" not found`
**Solution**: Use correct service name: `devicestatus-service`

### Debugging Commands
```bash
# Check pod status
kubectl describe pod <pod-name> -n devicestatus

# Check service
kubectl describe service devicestatus-service -n devicestatus

# Check deployment
kubectl describe deployment devicestatus-app -n devicestatus

# Check events
kubectl get events -n devicestatus --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name> -n devicestatus --previous
```

---

## Demo Script

### Pre-Demo Setup
1. Ensure all AWS resources are running
2. Verify Jenkins pipeline is working
3. Have LoadBalancer URL ready
4. Prepare sample data in database

### Demo Flow (15-20 minutes)

#### 1. Introduction (2 minutes)
- "Today I'll demonstrate a complete DevOps pipeline"
- "We'll deploy a Spring Boot application to AWS Kubernetes"
- "The pipeline includes: Docker, Jenkins, AWS EKS, and RDS"

#### 2. Show Application (2 minutes)
```bash
# Show the Spring Boot application
curl http://[LOADBALANCER_URL]/devicestatuses
curl http://[LOADBALANCER_URL]/actuator/health
```

#### 3. Show Infrastructure (3 minutes)
- AWS Console: Show RDS, EKS, ECR
- Jenkins Dashboard: Show pipeline runs
- Kubernetes Dashboard: Show pods and services

#### 4. Demonstrate CI/CD (5 minutes)
- Make a small code change
- Push to GitHub
- Show Jenkins pipeline running
- Show new deployment in Kubernetes

#### 5. Show Monitoring (3 minutes)
- Application logs
- Health checks
- Scaling capabilities

#### 6. Q&A (5 minutes)
- Answer questions about the architecture
- Explain benefits of this approach
- Discuss next steps

### Demo Talking Points
- **Scalability**: "Kubernetes can auto-scale based on load"
- **Reliability**: "Multiple replicas ensure high availability"
- **Security**: "Secrets are encrypted, network is isolated"
- **Automation**: "Entire process is automated from code to production"
- **Monitoring**: "Health checks and logging provide visibility"

---

## Summary

This guide provides a complete, step-by-step process for deploying a Spring Boot application to AWS Kubernetes using Docker and Jenkins. All the corrections and fixes from our actual deployment are included to ensure success.

### Key Success Factors:
1. **Correct Dockerfile** with multi-stage build
2. **Proper AWS CLI configuration** with full paths
3. **Accurate Jenkinsfile** with correct credentials
4. **Valid Kubernetes manifests** with correct image references
5. **Comprehensive troubleshooting** for common issues

### Architecture Benefits:
- **Fully automated** CI/CD pipeline
- **Scalable** containerized application
- **Secure** cloud infrastructure
- **Reliable** with health checks and monitoring
- **Cost-effective** using managed AWS services

This documentation should enable any developer to successfully deploy a Spring Boot application to AWS Kubernetes independently.

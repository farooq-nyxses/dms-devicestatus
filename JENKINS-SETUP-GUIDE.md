# Jenkins CI/CD Pipeline Setup Guide

## Overview
This guide walks you through setting up Jenkins for automated CI/CD deployment of the DeviceStatus Spring Boot application to AWS EKS.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Jenkins Installation](#jenkins-installation)
3. [Jenkins Configuration](#jenkins-configuration)
4. [Plugin Installation](#plugin-installation)
5. [Credentials Setup](#credentials-setup)
6. [Pipeline Job Creation](#pipeline-job-creation)
7. [Testing the Pipeline](#testing-the-pipeline)

---

## Prerequisites

Before setting up Jenkins, ensure you have:
- ✅ Java 17 or later installed
- ✅ AWS CLI configured with access to your AWS account
- ✅ kubectl installed and configured for EKS cluster
- ✅ Docker installed (if running Jenkins locally)
- ✅ GitHub repository with your application code
- ✅ Port 8080 available (default Jenkins port)

---

## Jenkins Installation

### Option 1: Windows Installation (Recommended for your setup)

1. **Download Jenkins**:
   - Visit: https://www.jenkins.io/download/
   - Download Jenkins Windows installer (.msi)

2. **Install Jenkins**:
   ```cmd
   # Run the downloaded .msi file
   # Follow the installation wizard
   # Default installation path: C:\Program Files\Jenkins
   ```

3. **Start Jenkins**:
   ```cmd
   # Jenkins will start automatically as a Windows service
   # Access Jenkins at: http://localhost:8080
   ```

4. **Unlock Jenkins**:
   ```cmd
   # Get the initial admin password
   type "C:\Program Files\Jenkins\secrets\initialAdminPassword"
   ```

### Option 2: Docker Installation

```bash
# Run Jenkins in Docker
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins \
  jenkins/jenkins:lts
```

---

## Jenkins Configuration

### 1. Initial Setup

1. **Access Jenkins**: Open browser and go to `http://localhost:8080`
2. **Unlock Jenkins**: Enter the initial admin password
3. **Install Suggested Plugins**: Click "Install suggested plugins"
4. **Create Admin User**: Set up your admin credentials

### 2. Global Tool Configuration

Navigate to: **Manage Jenkins** → **Global Tool Configuration**

#### Configure Maven
1. Click **Add Maven**
2. Name: `Maven 3.9.x`
3. Check "Install automatically"
4. Version: Select Maven 3.9.x or later
5. Click **Save**

#### Configure JDK
1. Click **Add JDK**
2. Name: `JDK 17`
3. Uncheck "Install automatically" if you have JDK installed
4. JAVA_HOME: `C:\Program Files\Java\jdk-17` (adjust to your path)
5. OR check "Install automatically" and select JDK 17
6. Click **Save**

#### Configure Docker (if needed)
1. Click **Add Docker**
2. Name: `Docker`
3. Check "Install automatically"
4. Click **Save**

---

## Plugin Installation

Navigate to: **Manage Jenkins** → **Manage Plugins** → **Available**

### Required Plugins

Search and install the following plugins:

1. **Git Plugin** (usually pre-installed)
   - For Git repository integration

2. **Docker Pipeline Plugin**
   - For Docker build steps in pipeline

3. **Kubernetes Plugin**
   - For Kubernetes deployment

4. **Kubernetes CLI Plugin**
   - For kubectl commands

5. **Pipeline Plugin** (usually pre-installed)
   - For Jenkinsfile pipeline support

6. **Blue Ocean** (Optional)
   - Modern UI for Jenkins pipelines

7. **JaCoCo Plugin**
   - For code coverage reports

8. **AWS Steps Plugin**
   - For AWS CLI integration

After selecting all plugins, click **Download now and install after restart**

---

## Credentials Setup

Navigate to: **Manage Jenkins** → **Manage Credentials** → **(global)** → **Add Credentials**

### 1. GitHub Credentials

**Type**: Username with password
- **Username**: Your GitHub username
- **Password**: GitHub Personal Access Token (PAT)
  - Generate PAT at: https://github.com/settings/tokens
  - Required scopes: `repo`, `admin:repo_hook`
- **ID**: `github-credentials`
- **Description**: GitHub Access Token
- Click **Create**

### 2. Database Password

**Type**: Secret text
- **Secret**: `DevStatus2024!`
- **ID**: `db-password`
- **Description**: RDS Database Password
- Click **Create**

### 3. AWS Credentials (if needed)

**Type**: AWS Credentials
- **Access Key ID**: Your AWS Access Key
- **Secret Access Key**: Your AWS Secret Key
- **ID**: `aws-credentials`
- **Description**: AWS Account Credentials
- Click **Create**

---

## Pipeline Job Creation

### Step 1: Create Pipeline Job

1. **From Jenkins Dashboard**: Click **New Item**
2. **Enter Job Name**: `devicestatus-pipeline`
3. **Select**: **Pipeline**
4. **Click**: **OK**

### Step 2: Configure Pipeline

#### General Section
- ☑ **Discard old builds**
  - Strategy: Log Rotation
  - Max # of builds to keep: `10`

#### Build Triggers
- ☑ **GitHub hook trigger for GITScm polling**
  - This enables automatic builds on git push

#### Pipeline Section
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/YOUR_GITHUB_USERNAME/dms-devicestatus.git`
  - ⚠️ Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username
- **Credentials**: Select `github-credentials`
- **Branch Specifier**: `*/main` (or your branch name)
- **Script Path**: `Jenkinsfile`

Click **Save**

---

## Jenkinsfile Configuration

Before running the pipeline, update the `Jenkinsfile` in your repository:

1. **Update Git Repository URL**:
   ```groovy
   REPO_URL = 'https://github.com/YOUR_GITHUB_USERNAME/dms-devicestatus.git'
   ```

2. **Verify AWS Configuration**:
   ```groovy
   AWS_REGION = 'ap-south-1'
   AWS_ACCOUNT_ID = '128121110035'
   EKS_CLUSTER_NAME = 'devicestatus-cluster'
   ```

3. **Verify Database Configuration**:
   ```groovy
   DB_URL = 'jdbc:postgresql://devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com:5432/devicestatus'
   DB_USERNAME = 'devicestatus'
   DB_PASSWORD = credentials('db-password')
   ```

---

## Jenkins Agent Configuration

### Configure Jenkins to Use AWS/kubectl

1. **Install AWS CLI on Jenkins Agent**:
   - If Jenkins is on Windows, install AWS CLI as you did locally
   - Path: `E:\Amazon\AWSCLIV2\aws.exe`

2. **Configure kubectl on Jenkins Agent**:
   ```cmd
   # Configure kubectl to access EKS
   aws eks update-kubeconfig --region ap-south-1 --name devicestatus-cluster
   ```

3. **Set Environment Variables** (Optional):
   - Navigate to: **Manage Jenkins** → **Configure System**
   - **Global properties** → **Environment variables**
   - Add:
     - Name: `AWS_REGION`, Value: `ap-south-1`
     - Name: `KUBECONFIG`, Value: `C:\Users\{your-user}\.kube\config`

---

## Testing the Pipeline

### Step 1: Run Pipeline Manually

1. **Go to Pipeline Job**: Click on `devicestatus-pipeline`
2. **Click**: **Build Now**
3. **Monitor Progress**: Click on build number (e.g., #1)
4. **View Console Output**: Click **Console Output**

### Step 2: Verify Pipeline Stages

The pipeline should execute these stages:
1. ✅ Checkout - Pull code from GitHub
2. ✅ Build & Test - Maven compile and test
3. ✅ Package - Create JAR file
4. ✅ Docker Build - Build Docker image
5. ✅ Docker Push to ECR - Push image to AWS ECR
6. ✅ Configure kubectl - Set up Kubernetes access
7. ✅ Deploy to Kubernetes - Deploy to EKS
8. ✅ Health Check - Verify deployment

### Step 3: Verify Deployment

```cmd
# Check pods
kubectl get pods -n devicestatus

# Check service
kubectl get svc -n devicestatus

# Test application
curl http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses
```

---

## GitHub Webhook Setup (Automatic Builds)

### Step 1: Get Jenkins Webhook URL

```
http://YOUR_JENKINS_URL:8080/github-webhook/
```

Example: `http://localhost:8080/github-webhook/`

### Step 2: Configure GitHub Webhook

1. **Go to GitHub Repository**
2. **Settings** → **Webhooks** → **Add webhook**
3. **Payload URL**: `http://YOUR_JENKINS_URL:8080/github-webhook/`
4. **Content type**: `application/json`
5. **Events**: Select "Just the push event"
6. **Active**: ☑ Check
7. **Add webhook**

⚠️ **Note**: If Jenkins is on localhost, you'll need to:
- Expose Jenkins using ngrok or similar tool
- OR deploy Jenkins to a public server
- OR use GitHub polling instead of webhooks

### Alternative: GitHub Polling

In Pipeline Configuration:
- **Build Triggers** → ☑ **Poll SCM**
- **Schedule**: `H/5 * * * *` (every 5 minutes)

---

## Troubleshooting

### Common Issues

#### 1. AWS CLI Not Found
**Error**: `aws: command not found`

**Solution**:
```cmd
# Add AWS CLI to PATH in Jenkins
# Manage Jenkins → Configure System → Environment variables
# Add: PATH = E:\Amazon\AWSCLIV2;%PATH%
```

#### 2. kubectl Not Found
**Error**: `kubectl: command not found`

**Solution**:
```cmd
# Install kubectl on Jenkins agent
# OR add kubectl path to Jenkins environment
```

#### 3. Docker Permission Denied
**Error**: `permission denied while trying to connect to Docker daemon`

**Solution**:
- Ensure Jenkins user has Docker permissions
- On Windows: Run Jenkins as Administrator
- On Linux: Add Jenkins user to docker group

#### 4. ECR Login Failed
**Error**: `Error response from daemon: Get https://128121110035.dkr.ecr.ap-south-1.amazonaws.com`

**Solution**:
```cmd
# Ensure AWS credentials are configured correctly
aws configure
# OR add AWS credentials in Jenkins
```

#### 5. kubectl Unable to Connect to Cluster
**Error**: `Unable to connect to the server`

**Solution**:
```cmd
# Update kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name devicestatus-cluster
```

---

## Security Best Practices

1. **Use Credentials Manager**:
   - Never hardcode passwords in Jenkinsfile
   - Always use Jenkins credentials

2. **Limit Access**:
   - Use Jenkins security matrix
   - Create separate users for different roles

3. **Secure Jenkins**:
   - Enable HTTPS
   - Use strong admin password
   - Keep Jenkins updated

4. **AWS IAM Roles**:
   - Use IAM roles instead of access keys when possible
   - Follow principle of least privilege

---

## Pipeline Flow Diagram

```
┌─────────────────┐
│   Git Push      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Jenkins Webhook│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Checkout     │ ← Pull code from GitHub
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build & Test   │ ← Maven compile + unit tests
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Package      │ ← Create JAR file
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Docker Build   │ ← Build Docker image
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Push to ECR     │ ← Upload to AWS container registry
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Configure kubectl│ ← Set up Kubernetes access
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Deploy to EKS  │ ← Rolling update on Kubernetes
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Health Check   │ ← Verify deployment
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Success! 🎉   │
└─────────────────┘
```

---

## Resources

- **Your Application URL**: http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com
- **Jenkins Dashboard**: http://localhost:8080
- **AWS EKS Cluster**: devicestatus-cluster
- **AWS ECR Repository**: 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app
- **RDS Database**: devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com

---

## Next Steps

1. ✅ Install Jenkins
2. ✅ Configure plugins and tools
3. ✅ Set up credentials
4. ✅ Create pipeline job
5. ✅ Run first build
6. ✅ Set up GitHub webhook
7. ✅ Test automatic deployment

**Congratulations!** You now have a complete CI/CD pipeline deploying your Spring Boot application to AWS EKS! 🚀


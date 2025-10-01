# Jenkins Setup Guide

## Prerequisites
- Java 17 or higher
- Maven 3.9.x
- Docker
- AWS CLI
- kubectl (Kubernetes CLI)

## Jenkins Installation

### Option 1: Docker Installation (Recommended)
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

### Option 2: Local Installation
1. Download Jenkins WAR file from https://jenkins.io/download/
2. Run: `java -jar jenkins.war --httpPort=8080`

## Initial Setup

1. **Access Jenkins**: http://localhost:8080
2. **Get initial password**: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. **Install suggested plugins**
4. **Create admin user**

## Required Plugins

Install these plugins via Manage Jenkins > Manage Plugins:

- **Pipeline**: For pipeline as code
- **Docker Pipeline**: For Docker integration
- **AWS Steps**: For AWS integration
- **Kubernetes**: For Kubernetes deployment
- **JaCoCo**: For code coverage
- **Git**: For Git integration
- **Credentials Binding**: For secure credential management

## Credentials Setup

Go to Manage Jenkins > Manage Credentials > System > Global credentials:

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

## Pipeline Configuration

1. **Create New Item** > **Pipeline**
2. **Pipeline Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: Your GitHub repository
5. **Credentials**: Select `github-farooq`
6. **Script Path**: Jenkinsfile

## Tools Configuration

Go to Manage Jenkins > Global Tool Configuration:

- **Maven**: Install Maven 3.9.x
- **JDK**: Install JDK 17
- **Docker**: Ensure Docker is available in PATH

## Pipeline Stages Explained

1. **Checkout**: Pulls code from Git repository
2. **Build & Test**: Compiles code and runs tests with coverage
3. **Package**: Creates JAR file
4. **Docker Build**: Builds Docker image
5. **Docker Push to ECR**: Pushes image to AWS ECR
6. **Deploy to Kubernetes**: Updates Kubernetes deployment
7. **Health Check**: Verifies deployment success

## Troubleshooting

### Common Issues:
1. **Docker permission denied**: Add Jenkins user to docker group
2. **AWS credentials not found**: Verify credential IDs match pipeline
3. **Kubernetes connection failed**: Check kubectl configuration
4. **ECR login failed**: Verify AWS credentials and region

### Logs:
- Pipeline logs: Available in Jenkins UI
- Docker logs: `docker logs jenkins`
- Application logs: Available in Kubernetes pods

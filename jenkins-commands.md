# Jenkins Quick Reference Commands

## Windows Commands for Jenkins Setup

### Check Java Version
```cmd
java -version
```

### Check Maven Version
```cmd
mvn -version
```

### Check Docker Version
```cmd
docker --version
```

### Check AWS CLI
```cmd
aws --version
aws configure list
```

### Check kubectl
```cmd
kubectl version --client
kubectl get nodes
```

## Configure kubectl for EKS
```cmd
aws eks update-kubeconfig --region ap-south-1 --name devicestatus-cluster
kubectl config current-context
kubectl config get-contexts
```

## Verify Kubernetes Deployment
```cmd
# Check pods
kubectl get pods -n devicestatus

# Check services
kubectl get svc -n devicestatus

# Check deployments
kubectl get deployments -n devicestatus

# Describe pod
kubectl describe pod <pod-name> -n devicestatus

# View logs
kubectl logs <pod-name> -n devicestatus

# View logs (follow)
kubectl logs -f <pod-name> -n devicestatus
```

## Docker Commands for Jenkins
```cmd
# List images
docker images

# List containers
docker ps -a

# Remove image
docker rmi <image-name>

# Remove container
docker rm <container-name>

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 128121110035.dkr.ecr.ap-south-1.amazonaws.com

# Build image
docker build -t devicestatus-app:latest .

# Tag image for ECR
docker tag devicestatus-app:latest 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:latest

# Push to ECR
docker push 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app:latest
```

## Test Application
```cmd
# Using PowerShell
Invoke-WebRequest -Uri http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses -UseBasicParsing

# Get JSON content
(Invoke-WebRequest -Uri http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/devicestatuses -UseBasicParsing).Content

# Health check
(Invoke-WebRequest -Uri http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com/actuator/health -UseBasicParsing).Content
```

## AWS Commands
```cmd
# Describe EKS cluster
aws eks describe-cluster --name devicestatus-cluster --region ap-south-1

# List ECR repositories
aws ecr describe-repositories --region ap-south-1

# List ECR images
aws ecr describe-images --repository-name devicestatus-app --region ap-south-1

# Describe RDS instance
aws rds describe-db-instances --db-instance-identifier devicestatus-db --region ap-south-1

# List EC2 instances (EKS nodes)
aws ec2 describe-instances --filters "Name=tag:eks:nodegroup-name,Values=devicestatus-nodes-v2" --region ap-south-1
```

## Jenkins Service Management (Windows)

### Start Jenkins Service
```cmd
net start jenkins
```

### Stop Jenkins Service
```cmd
net stop jenkins
```

### Restart Jenkins Service
```cmd
net stop jenkins
net start jenkins
```

### Check Jenkins Service Status
```cmd
sc query jenkins
```

## Troubleshooting Commands

### Check if port 8080 is in use
```cmd
netstat -ano | findstr :8080
```

### View Jenkins logs (Windows)
```cmd
type "C:\Program Files\Jenkins\jenkins.out.log"
```

### Reset Jenkins admin password
1. Stop Jenkins service
2. Edit config file: `C:\Program Files\Jenkins\config.xml`
3. Set `<useSecurity>false</useSecurity>`
4. Restart Jenkins
5. Reset password in UI
6. Re-enable security

## Useful Jenkins URLs

- **Jenkins Dashboard**: http://localhost:8080
- **Manage Jenkins**: http://localhost:8080/manage
- **Credentials**: http://localhost:8080/credentials/
- **System Log**: http://localhost:8080/log/all
- **Script Console**: http://localhost:8080/script

## Jenkins Groovy Script Examples

### Get Jenkins Version
```groovy
println(Jenkins.instance.getVersion())
```

### List All Jobs
```groovy
Jenkins.instance.getAllItems(AbstractItem.class).each {
    println(it.fullName)
}
```

### List All Credentials
```groovy
import com.cloudbees.plugins.credentials.CredentialsProvider

CredentialsProvider.lookupCredentials(
    com.cloudbees.plugins.credentials.common.StandardCredentials.class
).each {
    println(it.id)
}
```

## GitHub Personal Access Token

Create a PAT at: https://github.com/settings/tokens

Required scopes:
- `repo` - Full control of private repositories
- `admin:repo_hook` - Full control of repository hooks
- `workflow` - Update GitHub Action workflows

## Maven Commands

### Clean and build
```cmd
mvn clean install
```

### Run tests
```cmd
mvn test
```

### Package (skip tests)
```cmd
mvn package -DskipTests
```

### Run locally
```cmd
mvn spring-boot:run
```

## Your Deployment Information

- **Application URL**: http://aba523946c4734c4299ff347ffa4a63b-1227687436.ap-south-1.elb.amazonaws.com
- **EKS Cluster**: devicestatus-cluster
- **Namespace**: devicestatus
- **ECR Repository**: 128121110035.dkr.ecr.ap-south-1.amazonaws.com/devicestatus-app
- **RDS Endpoint**: devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com
- **AWS Region**: ap-south-1
- **AWS Account ID**: 128121110035


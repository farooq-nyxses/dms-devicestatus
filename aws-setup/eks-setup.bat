@echo off
REM EKS Setup Script for DeviceStatus Application (Windows)

echo 🚀 Setting up AWS EKS cluster...

REM Configuration
set CLUSTER_NAME=devicestatus-cluster
set REGION=ap-south-1
set NODE_GROUP_NAME=devicestatus-nodes
set NODE_TYPE=t3.medium
set NODE_COUNT=2
set MIN_NODE_COUNT=1
set MAX_NODE_COUNT=4

REM Load VPC resources from file
for /f "tokens=2 delims==" %%a in ('findstr "VPC_ID" aws-resources.txt') do set VPC_ID=%%a
for /f "tokens=2 delims==" %%a in ('findstr "PUBLIC_SUBNET_1_ID" aws-resources.txt') do set PUBLIC_SUBNET_1_ID=%%a
for /f "tokens=2 delims==" %%a in ('findstr "PUBLIC_SUBNET_2_ID" aws-resources.txt') do set PUBLIC_SUBNET_2_ID=%%a
for /f "tokens=2 delims==" %%a in ('findstr "EKS_SG_ID" aws-resources.txt') do set EKS_SG_ID=%%a

echo ✅ VPC ID: %VPC_ID%
echo ✅ Public Subnet 1: %PUBLIC_SUBNET_1_ID%
echo ✅ Public Subnet 2: %PUBLIC_SUBNET_2_ID%
echo ✅ EKS Security Group: %EKS_SG_ID%

REM Check if AWS CLI is configured
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not configured. Please run 'aws configure' first.
    exit /b 1
)

REM Check if eksctl is installed
eksctl version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ eksctl is not installed. Please install it first.
    echo    Install: https://eksctl.io/introduction/#installation
    exit /b 1
)

echo ✅ AWS CLI and eksctl configured successfully

REM Create EKS cluster
echo 🏗️  Creating EKS cluster...
eksctl create cluster ^
    --name %CLUSTER_NAME% ^
    --region %REGION% ^
    --version 1.28 ^
    --nodegroup-name %NODE_GROUP_NAME% ^
    --node-type %NODE_TYPE% ^
    --nodes %NODE_COUNT% ^
    --nodes-min %MIN_NODE_COUNT% ^
    --nodes-max %MAX_NODE_COUNT% ^
    --managed ^
    --with-oidc ^
    --ssh-access ^
    --tags Environment=Production,Name=DeviceStatus-EKS ^
    --timeout 20m

REM Update kubeconfig
echo 🔧 Updating kubeconfig...
aws eks update-kubeconfig --region %REGION% --name %CLUSTER_NAME%

REM Verify cluster access
echo ✅ Verifying cluster access...
kubectl get nodes

REM Create namespace
echo 📋 Creating namespace...
kubectl create namespace devicestatus 2>nul || echo ⚠️  Namespace might already exist

REM Install AWS Load Balancer Controller
echo ⚖️  Installing AWS Load Balancer Controller...
eksctl utils associate-iam-oidc-provider --cluster %CLUSTER_NAME% --approve

REM Create IAM policy for Load Balancer Controller
echo 📋 Creating IAM policy for Load Balancer Controller...
aws iam create-policy ^
    --policy-name AWSLoadBalancerControllerIAMPolicy ^
    --policy-document file://aws-load-balancer-controller-iam-policy.json 2>nul || echo ⚠️  Policy might already exist

REM Create IAM service account
eksctl create iamserviceaccount ^
    --cluster=%CLUSTER_NAME% ^
    --namespace=kube-system ^
    --name=aws-load-balancer-controller ^
    --role-name AmazonEKSLoadBalancerControllerRole ^
    --attach-policy-arn=arn:aws:iam::%AWS_ACCOUNT_ID%:policy/AWSLoadBalancerControllerIAMPolicy ^
    --approve

REM Install AWS Load Balancer Controller using Helm
echo 📦 Installing AWS Load Balancer Controller...
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller ^
    -n kube-system ^
    --set clusterName=%CLUSTER_NAME% ^
    --set serviceAccount.create=false ^
    --set serviceAccount.name=aws-load-balancer-controller

echo ✅ EKS cluster setup completed!
echo.
echo 📋 Cluster Information:
echo    Cluster Name: %CLUSTER_NAME%
echo    Region: %REGION%
echo    Node Group: %NODE_GROUP_NAME%
echo    Node Type: %NODE_TYPE%
echo    Node Count: %NODE_COUNT%
echo.
echo 🔧 Next Steps:
echo    1. Update Jenkins pipeline with cluster information
echo    2. Deploy your application using kubectl
echo    3. Configure ingress for external access
echo.
echo ⚠️  Important Notes:
echo    1. Cluster has OIDC provider enabled for IAM integration
echo    2. AWS Load Balancer Controller is installed for ingress
echo    3. Nodes are managed and auto-scaling is enabled
echo    4. SSH access is configured for debugging

REM Save EKS info to file
echo EKS_CLUSTER_NAME=%CLUSTER_NAME% >> aws-resources.txt
echo EKS_NODE_GROUP_NAME=%NODE_GROUP_NAME% >> aws-resources.txt

echo.
echo 📁 EKS information saved to aws-resources.txt
pause




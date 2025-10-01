@echo off
REM VPC and Networking Setup Script for DeviceStatus Application (Windows)

echo 🚀 Setting up VPC and networking infrastructure...

REM Check if AWS CLI is configured
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not configured. Please run 'aws configure' first.
    exit /b 1
)

echo ✅ AWS CLI configured successfully

REM Configuration
set VPC_CIDR=10.0.0.0/16
set PUBLIC_SUBNET_1_CIDR=10.0.1.0/24
set PUBLIC_SUBNET_2_CIDR=10.0.2.0/24
set PRIVATE_SUBNET_1_CIDR=10.0.10.0/24
set PRIVATE_SUBNET_2_CIDR=10.0.20.0/24
set AVAILABILITY_ZONE_1=ap-south-1a
set AVAILABILITY_ZONE_2=ap-south-1b
set REGION=ap-south-1

REM Create VPC
echo 📋 Creating VPC...
for /f "tokens=*" %%i in ('aws ec2 create-vpc --cidr-block %VPC_CIDR% --region %REGION% --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=DeviceStatus-VPC},{Key=Environment,Value=Production}]" --query "Vpc.VpcId" --output text') do set VPC_ID=%%i
echo ✅ VPC created: %VPC_ID%

REM Enable DNS hostnames and resolution
aws ec2 modify-vpc-attribute --vpc-id %VPC_ID% --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id %VPC_ID% --enable-dns-support

REM Create Internet Gateway
echo 📋 Creating Internet Gateway...
for /f "tokens=*" %%i in ('aws ec2 create-internet-gateway --region %REGION% --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=DeviceStatus-IGW},{Key=Environment,Value=Production}]" --query "InternetGateway.InternetGatewayId" --output text') do set IGW_ID=%%i
echo ✅ Internet Gateway created: %IGW_ID%

REM Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id %VPC_ID% --internet-gateway-id %IGW_ID%

REM Create Public Subnet 1
echo 📋 Creating Public Subnet 1...
for /f "tokens=*" %%i in ('aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block %PUBLIC_SUBNET_1_CIDR% --availability-zone %AVAILABILITY_ZONE_1% --region %REGION% --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=DeviceStatus-Public-Subnet-1},{Key=Environment,Value=Production}]" --query "Subnet.SubnetId" --output text') do set PUBLIC_SUBNET_1_ID=%%i
echo ✅ Public Subnet 1 created: %PUBLIC_SUBNET_1_ID%

REM Create Public Subnet 2
echo 📋 Creating Public Subnet 2...
for /f "tokens=*" %%i in ('aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block %PUBLIC_SUBNET_2_CIDR% --availability-zone %AVAILABILITY_ZONE_2% --region %REGION% --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=DeviceStatus-Public-Subnet-2},{Key=Environment,Value=Production}]" --query "Subnet.SubnetId" --output text') do set PUBLIC_SUBNET_2_ID=%%i
echo ✅ Public Subnet 2 created: %PUBLIC_SUBNET_2_ID%

REM Create Private Subnet 1
echo 📋 Creating Private Subnet 1...
for /f "tokens=*" %%i in ('aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block %PRIVATE_SUBNET_1_CIDR% --availability-zone %AVAILABILITY_ZONE_1% --region %REGION% --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=DeviceStatus-Private-Subnet-1},{Key=Environment,Value=Production}]" --query "Subnet.SubnetId" --output text') do set PRIVATE_SUBNET_1_ID=%%i
echo ✅ Private Subnet 1 created: %PRIVATE_SUBNET_1_ID%

REM Create Private Subnet 2
echo 📋 Creating Private Subnet 2...
for /f "tokens=*" %%i in ('aws ec2 create-subnet --vpc-id %VPC_ID% --cidr-block %PRIVATE_SUBNET_2_CIDR% --availability-zone %AVAILABILITY_ZONE_2% --region %REGION% --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=DeviceStatus-Private-Subnet-2},{Key=Environment,Value=Production}]" --query "Subnet.SubnetId" --output text') do set PRIVATE_SUBNET_2_ID=%%i
echo ✅ Private Subnet 2 created: %PRIVATE_SUBNET_2_ID%

REM Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute --subnet-id %PUBLIC_SUBNET_1_ID% --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id %PUBLIC_SUBNET_2_ID% --map-public-ip-on-launch

REM Create Route Table for Public Subnets
echo 📋 Creating Public Route Table...
for /f "tokens=*" %%i in ('aws ec2 create-route-table --vpc-id %VPC_ID% --region %REGION% --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=DeviceStatus-Public-RT},{Key=Environment,Value=Production}]" --query "RouteTable.RouteTableId" --output text') do set PUBLIC_RT_ID=%%i
echo ✅ Public Route Table created: %PUBLIC_RT_ID%

REM Create Route Table for Private Subnets
echo 📋 Creating Private Route Table...
for /f "tokens=*" %%i in ('aws ec2 create-route-table --vpc-id %VPC_ID% --region %REGION% --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=DeviceStatus-Private-RT},{Key=Environment,Value=Production}]" --query "RouteTable.RouteTableId" --output text') do set PRIVATE_RT_ID=%%i
echo ✅ Private Route Table created: %PRIVATE_RT_ID%

REM Add route to Internet Gateway for public subnets
aws ec2 create-route --route-table-id %PUBLIC_RT_ID% --destination-cidr-block 0.0.0.0/0 --gateway-id %IGW_ID%

REM Associate subnets with route tables
aws ec2 associate-route-table --subnet-id %PUBLIC_SUBNET_1_ID% --route-table-id %PUBLIC_RT_ID%
aws ec2 associate-route-table --subnet-id %PUBLIC_SUBNET_2_ID% --route-table-id %PUBLIC_RT_ID%
aws ec2 associate-route-table --subnet-id %PRIVATE_SUBNET_1_ID% --route-table-id %PRIVATE_RT_ID%
aws ec2 associate-route-table --subnet-id %PRIVATE_SUBNET_2_ID% --route-table-id %PRIVATE_RT_ID%

REM Create Security Groups
echo 📋 Creating Security Groups...

REM EKS Security Group
for /f "tokens=*" %%i in ('aws ec2 create-security-group --group-name DeviceStatus-EKS-SG --description "Security group for EKS cluster" --vpc-id %VPC_ID% --region %REGION% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=DeviceStatus-EKS-SG},{Key=Environment,Value=Production}]" --query "GroupId" --output text') do set EKS_SG_ID=%%i
echo ✅ EKS Security Group created: %EKS_SG_ID%

REM RDS Security Group
for /f "tokens=*" %%i in ('aws ec2 create-security-group --group-name DeviceStatus-RDS-SG --description "Security group for RDS PostgreSQL" --vpc-id %VPC_ID% --region %REGION% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=DeviceStatus-RDS-SG},{Key=Environment,Value=Production}]" --query "GroupId" --output text') do set RDS_SG_ID=%%i
echo ✅ RDS Security Group created: %RDS_SG_ID%

REM ALB Security Group
for /f "tokens=*" %%i in ('aws ec2 create-security-group --group-name DeviceStatus-ALB-SG --description "Security group for Application Load Balancer" --vpc-id %VPC_ID% --region %REGION% --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=DeviceStatus-ALB-SG},{Key=Environment,Value=Production}]" --query "GroupId" --output text') do set ALB_SG_ID=%%i
echo ✅ ALB Security Group created: %ALB_SG_ID%

REM Add security group rules
aws ec2 authorize-security-group-ingress --group-id %EKS_SG_ID% --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %EKS_SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %RDS_SG_ID% --protocol tcp --port 5432 --source-group %EKS_SG_ID%
aws ec2 authorize-security-group-ingress --group-id %ALB_SG_ID% --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id %ALB_SG_ID% --protocol tcp --port 443 --cidr 0.0.0.0/0

echo ✅ VPC and networking setup completed!
echo.
echo 📋 Infrastructure Information:
echo    VPC ID: %VPC_ID%
echo    Internet Gateway: %IGW_ID%
echo    Public Subnet 1: %PUBLIC_SUBNET_1_ID% (%AVAILABILITY_ZONE_1%)
echo    Public Subnet 2: %PUBLIC_SUBNET_2_ID% (%AVAILABILITY_ZONE_2%)
echo    Private Subnet 1: %PRIVATE_SUBNET_1_ID% (%AVAILABILITY_ZONE_1%)
echo    Private Subnet 2: %PRIVATE_SUBNET_2_ID% (%AVAILABILITY_ZONE_2%)
echo    Public Route Table: %PUBLIC_RT_ID%
echo    Private Route Table: %PRIVATE_RT_ID%
echo    EKS Security Group: %EKS_SG_ID%
echo    RDS Security Group: %RDS_SG_ID%
echo    ALB Security Group: %ALB_SG_ID%
echo.
echo ⚠️  Important: Save these IDs for the next steps!
echo    You'll need them for RDS, EKS, and ECR setup.

REM Save IDs to file for next steps
echo VPC_ID=%VPC_ID% > aws-resources.txt
echo IGW_ID=%IGW_ID% >> aws-resources.txt
echo PUBLIC_SUBNET_1_ID=%PUBLIC_SUBNET_1_ID% >> aws-resources.txt
echo PUBLIC_SUBNET_2_ID=%PUBLIC_SUBNET_2_ID% >> aws-resources.txt
echo PRIVATE_SUBNET_1_ID=%PRIVATE_SUBNET_1_ID% >> aws-resources.txt
echo PRIVATE_SUBNET_2_ID=%PRIVATE_SUBNET_2_ID% >> aws-resources.txt
echo PUBLIC_RT_ID=%PUBLIC_RT_ID% >> aws-resources.txt
echo PRIVATE_RT_ID=%PRIVATE_RT_ID% >> aws-resources.txt
echo EKS_SG_ID=%EKS_SG_ID% >> aws-resources.txt
echo RDS_SG_ID=%RDS_SG_ID% >> aws-resources.txt
echo ALB_SG_ID=%ALB_SG_ID% >> aws-resources.txt

echo.
echo 📁 Resource IDs saved to aws-resources.txt
pause

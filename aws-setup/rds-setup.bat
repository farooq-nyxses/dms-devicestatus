@echo off
REM RDS PostgreSQL Setup Script for DeviceStatus Application (Windows)

echo 🚀 Setting up AWS RDS PostgreSQL database...

REM Configuration
set DB_INSTANCE_IDENTIFIER=devicestatus-db
set DB_NAME=devicestatus
set DB_USERNAME=devicestatus
set DB_PASSWORD=DevStatus2024!
set DB_INSTANCE_CLASS=db.t3.micro
set DB_ENGINE=postgres
set DB_ENGINE_VERSION=16.3
set DB_ALLOCATED_STORAGE=20
set DB_STORAGE_TYPE=gp2
set VPC_SECURITY_GROUP_ID=sg-0f093f69f768baea9
set DB_SUBNET_GROUP_NAME=devicestatus-subnet-group
set AVAILABILITY_ZONE=ap-south-1a
set REGION=ap-south-1

REM Load VPC resources from file
for /f "tokens=2 delims==" %%a in ('findstr "VPC_ID" aws-resources.txt') do set VPC_ID=%%a
for /f "tokens=2 delims==" %%a in ('findstr "PRIVATE_SUBNET_1_ID" aws-resources.txt') do set PRIVATE_SUBNET_1_ID=%%a
for /f "tokens=2 delims==" %%a in ('findstr "PRIVATE_SUBNET_2_ID" aws-resources.txt') do set PRIVATE_SUBNET_2_ID=%%a

echo ✅ VPC ID: %VPC_ID%
echo ✅ Private Subnet 1: %PRIVATE_SUBNET_1_ID%
echo ✅ Private Subnet 2: %PRIVATE_SUBNET_2_ID%

REM Check if AWS CLI is configured
"E:\Amazon\AWSCLIV2\aws.exe" sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not configured. Please run 'aws configure' first.
    exit /b 1
)

echo ✅ AWS CLI configured successfully

REM Create DB subnet group
echo 📋 Creating DB subnet group...
"E:\Amazon\AWSCLIV2\aws.exe" rds create-db-subnet-group ^
    --db-subnet-group-name %DB_SUBNET_GROUP_NAME% ^
    --db-subnet-group-description "Subnet group for DeviceStatus application" ^
    --subnet-ids %PRIVATE_SUBNET_1_ID% %PRIVATE_SUBNET_2_ID% ^
    --region %REGION% ^
    --tags Key=Name,Value=DeviceStatus-SubnetGroup Key=Environment,Value=Production 2>nul || echo ⚠️  DB subnet group might already exist

REM Create RDS instance
echo 🗄️  Creating RDS PostgreSQL instance...
aws rds create-db-instance ^
    --db-instance-identifier %DB_INSTANCE_IDENTIFIER% ^
    --db-instance-class %DB_INSTANCE_CLASS% ^
    --engine %DB_ENGINE% ^
    --engine-version %DB_ENGINE_VERSION% ^
    --master-username %DB_USERNAME% ^
    --master-user-password %DB_PASSWORD% ^
    --allocated-storage %DB_ALLOCATED_STORAGE% ^
    --storage-type %DB_STORAGE_TYPE% ^
    --db-name %DB_NAME% ^
    --vpc-security-group-ids %VPC_SECURITY_GROUP_ID% ^
    --db-subnet-group-name %DB_SUBNET_GROUP_NAME% ^
    --availability-zone %AVAILABILITY_ZONE% ^
    --backup-retention-period 7 ^
    --multi-az ^
    --storage-encrypted ^
    --region %REGION% ^
    --tags Key=Name,Value=DeviceStatus-Database Key=Environment,Value=Production 2>nul || echo ⚠️  RDS instance might already exist

echo ⏳ Waiting for RDS instance to be available...
aws rds wait db-instance-available ^
    --db-instance-identifier %DB_INSTANCE_IDENTIFIER% ^
    --region %REGION%

REM Get endpoint information
echo 📊 Getting database endpoint...
for /f "tokens=*" %%i in ('aws rds describe-db-instances --db-instance-identifier %DB_INSTANCE_IDENTIFIER% --region %REGION% --query "DBInstances[0].Endpoint.Address" --output text') do set DB_ENDPOINT=%%i

for /f "tokens=*" %%i in ('aws rds describe-db-instances --db-instance-identifier %DB_INSTANCE_IDENTIFIER% --region %REGION% --query "DBInstances[0].Endpoint.Port" --output text') do set DB_PORT=%%i

echo ✅ RDS PostgreSQL setup completed!
echo.
echo 📋 Database Information:
echo    Instance ID: %DB_INSTANCE_IDENTIFIER%
echo    Endpoint: %DB_ENDPOINT%
echo    Port: %DB_PORT%
echo    Database Name: %DB_NAME%
echo    Username: %DB_USERNAME%
echo    Password: %DB_PASSWORD%
echo.
echo 🔗 Connection String:
echo    jdbc:postgresql://%DB_ENDPOINT%:%DB_PORT%/%DB_NAME%
echo.
echo ⚠️  Important Notes:
echo    1. Update your application properties with the new connection string
echo    2. Configure security groups to allow access from your EKS cluster
echo    3. Store credentials securely in Jenkins
echo    4. The database is encrypted and has automated backups enabled

REM Save database info to file
echo DB_ENDPOINT=%DB_ENDPOINT% >> aws-resources.txt
echo DB_PORT=%DB_PORT% >> aws-resources.txt
echo DB_NAME=%DB_NAME% >> aws-resources.txt
echo DB_USERNAME=%DB_USERNAME% >> aws-resources.txt
echo DB_PASSWORD=%DB_PASSWORD% >> aws-resources.txt

echo.
echo 📁 Database information saved to aws-resources.txt
pause

@echo off
REM ECR Setup Script for DeviceStatus Application (Windows) - Fixed Version

echo 🚀 Setting up AWS ECR repository...

REM Configuration
set ECR_REPOSITORY_NAME=devicestatus-app
set REGION=ap-south-1

REM Find AWS CLI path
set AWS_CLI_PATH=
if exist "E:\Amazon\AWSCLIV2\aws.exe" set AWS_CLI_PATH="E:\Amazon\AWSCLIV2\aws.exe"
if exist "C:\Program Files\Amazon\AWSCLIV2\aws.exe" set AWS_CLI_PATH="C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if exist "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe" set AWS_CLI_PATH="C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"

if "%AWS_CLI_PATH%"=="" (
    echo ❌ AWS CLI not found. Please install AWS CLI first.
    echo    Download from: https://aws.amazon.com/cli/
    pause
    exit /b 1
)

echo ✅ AWS CLI found at: %AWS_CLI_PATH%

REM Check if AWS CLI is configured
%AWS_CLI_PATH% sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ AWS CLI not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)

echo ✅ AWS CLI configured successfully

REM Get AWS account ID
for /f "tokens=*" %%i in ('%AWS_CLI_PATH% sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
echo 📋 AWS Account ID: %AWS_ACCOUNT_ID%

REM Create ECR repository
echo 📦 Creating ECR repository...
%AWS_CLI_PATH% ecr create-repository ^
    --repository-name %ECR_REPOSITORY_NAME% ^
    --region %REGION% ^
    --image-scanning-configuration scanOnPush=true ^
    --encryption-configuration encryptionType=AES256 ^
    --tags Key=Name,Value=DeviceStatus-ECR Key=Environment,Value=Production 2>nul || echo ⚠️  ECR repository might already exist

REM Set lifecycle policy
echo 📋 Setting lifecycle policy...
echo {> lifecycle-policy.json
echo     "rules": [>> lifecycle-policy.json
echo         {>> lifecycle-policy.json
echo             "rulePriority": 1,>> lifecycle-policy.json
echo             "description": "Keep last 10 production images",>> lifecycle-policy.json
echo             "selection": {>> lifecycle-policy.json
echo                 "tagStatus": "tagged",>> lifecycle-policy.json
echo                 "tagPrefixList": ["v"],>> lifecycle-policy.json
echo                 "countType": "imageCountMoreThan",>> lifecycle-policy.json
echo                 "countNumber": 10>> lifecycle-policy.json
echo             },>> lifecycle-policy.json
echo             "action": {>> lifecycle-policy.json
echo                 "type": "expire">> lifecycle-policy.json
echo             }>> lifecycle-policy.json
echo         },>> lifecycle-policy.json
echo         {>> lifecycle-policy.json
echo             "rulePriority": 2,>> lifecycle-policy.json
echo             "description": "Delete untagged images older than 1 day",>> lifecycle-policy.json
echo             "selection": {>> lifecycle-policy.json
echo                 "tagStatus": "untagged",>> lifecycle-policy.json
echo                 "countType": "sinceImagePushed",>> lifecycle-policy.json
echo                 "countUnit": "days",>> lifecycle-policy.json
echo                 "countNumber": 1>> lifecycle-policy.json
echo             },>> lifecycle-policy.json
echo             "action": {>> lifecycle-policy.json
echo                 "type": "expire">> lifecycle-policy.json
echo             }>> lifecycle-policy.json
echo         }>> lifecycle-policy.json
echo     ]>> lifecycle-policy.json
echo }>> lifecycle-policy.json

%AWS_CLI_PATH% ecr put-lifecycle-policy ^
    --repository-name %ECR_REPOSITORY_NAME% ^
    --region %REGION% ^
    --lifecycle-policy-text file://lifecycle-policy.json

REM Clean up temporary file
del lifecycle-policy.json

REM Get repository URI
set ECR_REPOSITORY_URI=%AWS_ACCOUNT_ID%.dkr.ecr.%REGION%.amazonaws.com/%ECR_REPOSITORY_NAME%

echo ✅ ECR repository setup completed!
echo.
echo 📋 Repository Information:
echo    Repository Name: %ECR_REPOSITORY_NAME%
echo    Repository URI: %ECR_REPOSITORY_URI%
echo    Region: %REGION%
echo.
echo 🔐 Login Command:
echo    %AWS_CLI_PATH% ecr get-login-password --region %REGION% ^| docker login --username AWS --password-stdin %ECR_REPOSITORY_URI%
echo.
echo 📦 Push Command Example:
echo    docker tag devicestatus-app:latest %ECR_REPOSITORY_URI%:latest
echo    docker push %ECR_REPOSITORY_URI%:latest
echo.
echo ⚠️  Important Notes:
echo    1. Update Jenkins pipeline with the repository URI
echo    2. Ensure IAM permissions allow ECR access
echo    3. Repository has image scanning enabled for security
echo    4. Lifecycle policy will automatically clean up old images

REM Save ECR info to file
echo ECR_REPOSITORY_URI=%ECR_REPOSITORY_URI% >> aws-resources.txt
echo ECR_REPOSITORY_NAME=%ECR_REPOSITORY_NAME% >> aws-resources.txt

echo.
echo 📁 ECR information saved to aws-resources.txt
pause



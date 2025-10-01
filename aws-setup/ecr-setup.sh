#!/bin/bash

# AWS ECR Setup Script
# This script creates an ECR repository for the DeviceStatus application

set -e

# Configuration
ECR_REPOSITORY_NAME="devicestatus-app"
REGION="ap-south-1"

echo "🚀 Setting up AWS ECR repository..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured successfully"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 AWS Account ID: $AWS_ACCOUNT_ID"

# Create ECR repository
echo "📦 Creating ECR repository..."
aws ecr create-repository \
    --repository-name $ECR_REPOSITORY_NAME \
    --region $REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256 \
    --tags Key=Name,Value=DeviceStatus-ECR Key=Environment,Value=Production \
    || echo "⚠️  ECR repository might already exist"

# Set lifecycle policy to manage image retention
echo "📋 Setting lifecycle policy..."
cat > lifecycle-policy.json << EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 production images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Delete untagged images older than 1 day",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

aws ecr put-lifecycle-policy \
    --repository-name $ECR_REPOSITORY_NAME \
    --region $REGION \
    --lifecycle-policy-text file://lifecycle-policy.json

# Clean up temporary file
rm lifecycle-policy.json

# Get repository URI
ECR_REPOSITORY_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY_NAME"

echo "✅ ECR repository setup completed!"
echo ""
echo "📋 Repository Information:"
echo "   Repository Name: $ECR_REPOSITORY_NAME"
echo "   Repository URI: $ECR_REPOSITORY_URI"
echo "   Region: $REGION"
echo ""
echo "🔐 Login Command:"
echo "   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI"
echo ""
echo "📦 Push Command Example:"
echo "   docker tag devicestatus-app:latest $ECR_REPOSITORY_URI:latest"
echo "   docker push $ECR_REPOSITORY_URI:latest"
echo ""
echo "⚠️  Important Notes:"
echo "   1. Update Jenkins pipeline with the repository URI"
echo "   2. Ensure IAM permissions allow ECR access"
echo "   3. Repository has image scanning enabled for security"
echo "   4. Lifecycle policy will automatically clean up old images"

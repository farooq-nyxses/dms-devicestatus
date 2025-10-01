#!/bin/bash

# AWS RDS PostgreSQL Setup Script
# This script creates a PostgreSQL RDS instance for the DeviceStatus application

set -e

# Configuration
DB_INSTANCE_IDENTIFIER="devicestatus-db"
DB_NAME="devicestatus"
DB_USERNAME="devicestatus"
DB_PASSWORD="DevStatus2024!"
DB_INSTANCE_CLASS="db.t3.micro"
DB_ENGINE="postgres"
DB_ENGINE_VERSION="15.4"
DB_ALLOCATED_STORAGE="20"
DB_STORAGE_TYPE="gp2"
VPC_SECURITY_GROUP_ID="sg-0f093f69f768baea9"  # Your RDS security group ID
DB_SUBNET_GROUP_NAME="devicestatus-subnet-group"
AVAILABILITY_ZONE="ap-south-1a"
REGION="ap-south-1"

echo "🚀 Setting up AWS RDS PostgreSQL database..."

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

# Create DB subnet group (if it doesn't exist)
echo "📋 Creating DB subnet group..."
aws rds create-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --db-subnet-group-description "Subnet group for DeviceStatus application" \
    --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy \
    --region $REGION \
    --tags Key=Name,Value=DeviceStatus-SubnetGroup Key=Environment,Value=Production \
    || echo "⚠️  DB subnet group might already exist"

# Create RDS instance
echo "🗄️  Creating RDS PostgreSQL instance..."
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine $DB_ENGINE \
    --engine-version $DB_ENGINE_VERSION \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --allocated-storage $DB_ALLOCATED_STORAGE \
    --storage-type $DB_STORAGE_TYPE \
    --db-name $DB_NAME \
    --vpc-security-group-ids $VPC_SECURITY_GROUP_ID \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --availability-zone $AVAILABILITY_ZONE \
    --backup-retention-period 7 \
    --multi-az \
    --storage-encrypted \
    --region $REGION \
    --tags Key=Name,Value=DeviceStatus-Database Key=Environment,Value=Production \
    || echo "⚠️  RDS instance might already exist"

echo "⏳ Waiting for RDS instance to be available..."
aws rds wait db-instance-available \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --region $REGION

# Get endpoint information
echo "📊 Getting database endpoint..."
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --region $REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

DB_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --region $REGION \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

echo "✅ RDS PostgreSQL setup completed!"
echo ""
echo "📋 Database Information:"
echo "   Instance ID: $DB_INSTANCE_IDENTIFIER"
echo "   Endpoint: $DB_ENDPOINT"
echo "   Port: $DB_PORT"
echo "   Database Name: $DB_NAME"
echo "   Username: $DB_USERNAME"
echo "   Password: $DB_PASSWORD"
echo ""
echo "🔗 Connection String:"
echo "   jdbc:postgresql://$DB_ENDPOINT:$DB_PORT/$DB_NAME"
echo ""
echo "⚠️  Important Notes:"
echo "   1. Update your application properties with the new connection string"
echo "   2. Configure security groups to allow access from your EKS cluster"
echo "   3. Store credentials securely in Jenkins"
echo "   4. The database is encrypted and has automated backups enabled"

#!/bin/bash

# Kubernetes Deployment Script for DeviceStatus Application

set -e

# Configuration
NAMESPACE="devicestatus"
AWS_ACCOUNT_ID="YOUR_AWS_ACCOUNT_ID"  # Replace with your AWS Account ID
AWS_REGION="ap-south-1"
ECR_REPOSITORY="devicestatus-app"
IMAGE_TAG="latest"

echo "🚀 Deploying DeviceStatus application to Kubernetes..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install it first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ kubectl and AWS CLI configured successfully"

# Update image in deployment.yaml
echo "📋 Updating deployment image..."
sed -i "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" deployment.yaml

# Create namespace
echo "📋 Creating namespace..."
kubectl apply -f namespace.yaml

# Apply ConfigMap
echo "📋 Applying ConfigMap..."
kubectl apply -f configmap.yaml

# Apply Secret (update with your actual values)
echo "📋 Applying Secret..."
echo "⚠️  Please update secret.yaml with your actual database credentials before proceeding"
kubectl apply -f secret.yaml

# Apply Deployment
echo "📋 Applying Deployment..."
kubectl apply -f deployment.yaml

# Apply Service
echo "📋 Applying Service..."
kubectl apply -f service.yaml

# Apply Ingress (optional - update with your domain and certificate)
echo "📋 Applying Ingress..."
echo "⚠️  Please update ingress.yaml with your domain and SSL certificate ARN before proceeding"
kubectl apply -f ingress.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/devicestatus-app -n $NAMESPACE --timeout=300s

# Get deployment information
echo "📊 Getting deployment information..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

# Get application logs
echo "📋 Getting application logs..."
kubectl logs -n $NAMESPACE -l app=devicestatus-app --tail=20

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Access Information:"
echo "   Namespace: $NAMESPACE"
echo "   Service: devicestatus-service"
echo "   Ingress: devicestatus-ingress"
echo ""
echo "🔧 Useful Commands:"
echo "   View pods: kubectl get pods -n $NAMESPACE"
echo "   View logs: kubectl logs -n $NAMESPACE -l app=devicestatus-app"
echo "   Scale deployment: kubectl scale deployment devicestatus-app --replicas=3 -n $NAMESPACE"
echo "   Port forward: kubectl port-forward -n $NAMESPACE service/devicestatus-service 8080:80"
echo ""
echo "⚠️  Important Notes:"
echo "   1. Update secret.yaml with your actual database credentials"
echo "   2. Update ingress.yaml with your domain and SSL certificate"
echo "   3. Ensure your ECR repository exists and is accessible"
echo "   4. Check security groups for database access"

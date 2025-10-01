pipeline {
  agent any

  options {
    timestamps()
    skipDefaultCheckout(true)
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  tools {
    maven 'Maven 3.9.x'
  }

  environment {
    // Git Configuration
    REPO_URL   = 'https://github.com/farooq-nyxses/dms-devicestatus.git'
    BRANCH     = 'dev-aws-branch'
    CRED_ID    = 'github-farooq-nyxses'
    
    // AWS Configuration
    AWS_REGION = 'ap-south-1'
    AWS_ACCOUNT_ID = '128121110035'
    ECR_REPOSITORY = 'devicestatus-app'
    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    EKS_CLUSTER_NAME = 'devicestatus-cluster'
    
    // AWS Credentials (using Jenkins credentials)
    AWS_ACCESS_KEY_ID = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    
    // Application Configuration
    APP_NAME = 'devicestatus-app'
    IMAGE_TAG = "${BUILD_NUMBER}"
    KUBE_NAMESPACE = 'devicestatus'
    
    // Database Configuration
    DB_URL = 'jdbc:postgresql://devicestatus-db.cb8cgs84gdsk.ap-south-1.rds.amazonaws.com:5432/devicestatus'
    DB_USERNAME = 'devicestatus'
    DB_PASSWORD = credentials('db-password')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: "${BRANCH}"]],
          userRemoteConfigs: [[url: REPO_URL, credentialsId: CRED_ID]]
        ])
      }
    }

    stage('Build & Test') {
      steps {
        bat 'mvn clean compile test'
      }
    }

    stage('Package') {
      steps {
        bat 'mvn clean package spring-boot:repackage -DskipTests'
      }
      post {
        always {
          archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
      }
    }

    stage('Docker Build') {
      steps {
        script {
          // Build Docker image
          bat "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
          bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest"
        }
      }
    }

    stage('Docker Push to ECR') {
      steps {
        script {
          // Login to ECR
          bat "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
          
          // Tag image for ECR
          bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
          bat "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
          
          // Push to ECR
          bat "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
          bat "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
        }
      }
    }

    stage('Configure kubectl') {
      steps {
        script {
          // Configure kubectl to use EKS cluster
          bat """
            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
            kubectl config current-context
          """
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        script {
          // Update Kubernetes deployment with new image
          bat """
            kubectl set image deployment/${APP_NAME} ${APP_NAME}=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
            kubectl rollout status deployment/${APP_NAME} -n ${KUBE_NAMESPACE} --timeout=300s
          """
        }
      }
    }

    stage('Health Check') {
      steps {
        script {
          // Get service endpoint
          bat """
            kubectl get service devicestatus-service -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
          """
          
          // Health check
          bat """
            timeout 30
            kubectl get pods -n ${KUBE_NAMESPACE} -l app=${APP_NAME}
            kubectl logs -n ${KUBE_NAMESPACE} -l app=${APP_NAME} --tail=50
          """
        }
      }
    }
  }

  post {
    always {
      // Clean up Docker images
      bat "docker rmi ${APP_NAME}:${IMAGE_TAG} || echo 'Image not found'"
      bat "docker rmi ${APP_NAME}:latest || echo 'Image not found'"
      
      // Clean workspace
      cleanWs()
    }
    
    success {
      echo 'Pipeline completed successfully!'
      echo 'Application deployed to AWS EKS!'
    }
    
    failure {
      echo 'Pipeline failed!'
    }
  }
}
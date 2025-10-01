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
        bat 'mvn package -DskipTests'
      }
      post {
        always {
          archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        }
      }
    }

    stage('Docker Build - SKIPPED') {
      steps {
        script {
          echo 'Docker Build stage skipped due to Docker Desktop issues'
          echo 'To enable: Fix Docker Desktop and uncomment the Docker stages below'
        }
      }
    }

    stage('Docker Push to ECR - SKIPPED') {
      steps {
        script {
          echo 'Docker Push stage skipped due to Docker Desktop issues'
          echo 'To enable: Fix Docker Desktop and uncomment the Docker stages below'
        }
      }
    }

    stage('Configure kubectl - SKIPPED') {
      steps {
        script {
          echo 'kubectl configuration skipped - AWS credentials not configured in Jenkins'
          echo 'To enable: Add AWS credentials to Jenkins and uncomment this stage'
        }
      }
    }

    stage('Deploy to Kubernetes - SKIPPED') {
      steps {
        script {
          echo 'Kubernetes deployment skipped - no new Docker image to deploy'
          echo 'Current deployment is still running with the previous image'
        }
      }
    }

    stage('Health Check - SKIPPED') {
      steps {
        script {
          echo 'Health check skipped - kubectl not configured'
          echo 'To enable: Configure AWS credentials and kubectl access'
        }
      }
    }
  }

  post {
    always {
      // Clean workspace
      cleanWs()
    }
    
    success {
      echo 'Pipeline completed successfully!'
      echo 'Note: Docker and Kubernetes stages were skipped due to configuration issues'
      echo 'Build artifacts are available in Jenkins'
    }
    
    failure {
      echo 'Pipeline failed!'
    }
  }
}
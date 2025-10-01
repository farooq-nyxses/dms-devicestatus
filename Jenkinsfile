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
    REPO_URL   = 'https://github.com/YOUR_GITHUB_USERNAME/dms-devicestatus.git'
    BRANCH     = 'main'
    CRED_ID    = 'github-credentials'
    
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
          branches: [[name: "*/${BRANCH}"]],
          userRemoteConfigs: [[url: REPO_URL, credentialsId: CRED_ID]]
        ])
      }
    }

    stage('Build & Test') {
      steps {
        sh 'mvn clean compile test'
      }
      post {
        always {
          publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
          publishCoverage adapters: [jacocoAdapter('target/site/jacoco/jacoco.xml')], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
        }
      }
    }

    stage('Package') {
      steps {
        sh 'mvn package -DskipTests'
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
          sh "docker build -t ${APP_NAME}:${IMAGE_TAG} ."
          sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest"
        }
      }
    }

    stage('Docker Push to ECR') {
      steps {
        script {
          // Login to ECR
          sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
          
          // Tag image for ECR
          sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
          sh "docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
          
          // Push to ECR
          sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
          sh "docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"
        }
      }
    }

    stage('Configure kubectl') {
      steps {
        script {
          // Configure kubectl to use EKS cluster
          sh """
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
          sh """
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
          sh """
            kubectl get service ${APP_NAME}-service -n ${KUBE_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
          """
          
          // Health check
          sh """
            sleep 30
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
      sh "docker rmi ${APP_NAME}:${IMAGE_TAG} || true"
      sh "docker rmi ${APP_NAME}:latest || true"
      
      // Clean workspace
      cleanWs()
    }
    
    success {
      echo 'Pipeline completed successfully!'
      // Send notification (Slack, email, etc.)
    }
    
    failure {
      echo 'Pipeline failed!'
      // Send failure notification
    }
  }
}

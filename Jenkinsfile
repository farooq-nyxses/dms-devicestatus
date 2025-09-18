pipeline {
  agent any

  tools {
    maven 'Maven 3.9.x'
  }

  environment {
    REPO_URL   = 'https://github.com/farooq-nyxses/dms-devicestatus.git'
    BRANCH     = 'dev-branch'
    CRED_ID    = 'github-farooq'
    DEPLOY_DIR = '/opt/dms-devicestatus'
    SERVICE    = 'devicestatus'
  }

  options {
    timestamps()
    skipDefaultCheckout(true)
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

    stage('Build (skip tests)') {
      steps {
        sh 'mvn -B -DskipTests clean package'
      }
    }

    stage('Deploy to server') {
      steps {
        sh '''
          set -e
          # Pick the built jar (name can vary); copy as app.jar
          JAR=$(ls -1 target/*.jar | head -n1)
          [ -f "$JAR" ] || { echo "No jar built in target/"; exit 1; }

          # Ensure deploy dir exists and is owned by jenkins
          sudo mkdir -p ${DEPLOY_DIR}
          sudo chown -R jenkins:jenkins ${DEPLOY_DIR}

          # Copy jar atomically
          cp "$JAR" ${DEPLOY_DIR}/app.jar

          # Reload systemd in case unit changed and restart the service
          sudo systemctl daemon-reload
          sudo systemctl restart ${SERVICE}

          # Quick health check (HTTP 200/403 are fine for HEAD)
          sleep 2
          curl -I --max-time 5 http://localhost:8082 || true
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
    }
  }
}

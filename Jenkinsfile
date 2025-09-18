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
	      set -euo pipefail
	
	      # 1) Find the built JAR
	      JAR="$(ls -1 target/*.jar | head -n1)"
	      echo "Built JAR: $JAR"
	      [ -f "$JAR" ] || { echo "No jar built in target/"; exit 1; }
	
	      # 2) Ensure deploy dir exists (owned by jenkins)
	      sudo -n install -d -o jenkins -g jenkins -m 0755 ${DEPLOY_DIR}
	
	      # 3) Copy JAR atomically with sane perms (0644) as app.jar
	      install -m 0644 "$JAR" ${DEPLOY_DIR}/app.jar
	      ls -l ${DEPLOY_DIR}/app.jar
	
	      # 4) Reload units and restart ONLY this service (NOPASSWD allowed)
	      sudo -n systemctl daemon-reload
	      sudo -n systemctl restart ${SERVICE}
	
	      # 5) Simple health wait (HTTP 200/302/403 all OK for HEAD)
	      echo "Waiting for app on http://localhost:8082 ..."
	      for i in $(seq 1 30); do
	        if curl -fsI --max-time 2 http://localhost:8082 >/dev/null 2>&1; then
	          echo "App is responding on port 8082."
	          exit 0
	        fi
	        sleep 1
	      done
	
	      echo "Service did not respond on 8082 in time." >&2
	      exit 1
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

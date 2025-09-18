pipeline {
  agent any

  options {
    timestamps()
    skipDefaultCheckout(true)
  }

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
        // Repackage to create a runnable Spring Boot fat jar
        sh 'mvn -B -DskipTests clean package spring-boot:repackage'
      }
    }

    stage('Deploy to server') {
      steps {
        // POSIX /bin/sh script
        sh '''
          set -eu

          # 1) Find the built JAR (after repackage it's still the same artifact name)
          JAR="$(ls -1 target/*.jar | head -n1)"
          echo "Built JAR: $JAR"
          if [ ! -f "$JAR" ]; then
            echo "No jar built in target/" >&2
            exit 1
          fi

          # 2) Ensure deploy dir exists (jenkins owns it; no sudo needed)
          mkdir -p "${DEPLOY_DIR}"

          # 3) Copy JAR as app.jar
          install -m 0644 "$JAR" "${DEPLOY_DIR}/app.jar"
          echo "app.jar size:"
          ls -lh "${DEPLOY_DIR}/app.jar"

          # 4) Reload unit files & restart the service (sudo allowed via sudoers)
          sudo -n systemctl daemon-reload
          sudo -n systemctl restart "${SERVICE}"

          # 5) Health check (wait up to ~30s)
          echo "Waiting for app on http://localhost:8082 ..."
          i=0
          until curl -fsI --max-time 2 http://localhost:8082 >/dev/null 2>&1; do
            i=$((i+1))
            if [ "$i" -ge 30 ]; then
              echo "Service did not respond on 8082 in time." >&2
              exit 1
            fi
            sleep 1
          done
          echo "App is responding on port 8082."
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

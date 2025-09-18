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
    CRED_ID    = 'github-farooq'              // Jenkins Credentials ID (Username + PAT)
    DEPLOY_DIR = '/opt/dms-devicestatus'      // Target dir on Ubuntu server
    SERVICE    = 'devicestatus'               // systemd service name
    HEALTH_URL = '/devicestatuses'            // <-- change if you prefer another endpoint
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
        // Build runnable Spring Boot JAR
        sh 'mvn -B -DskipTests clean package spring-boot:repackage'
      }
    }

    stage('Deploy to server') {
      steps {
        // POSIX /bin/sh compatible
        sh '''
          set -eu

          # 1) Find the built JAR
          JAR="$(ls -1 target/*.jar | head -n1)"
          echo "Built JAR: $JAR"
          if [ ! -f "$JAR" ]; then
            echo "No jar built in target/" >&2
            exit 1
          fi

          # 2) Ensure deploy dir exists (jenkins owns it; no sudo)
          mkdir -p "${DEPLOY_DIR}"

          # 3) Copy JAR as app.jar
          install -m 0644 "$JAR" "${DEPLOY_DIR}/app.jar"
          echo "app.jar size:"
          ls -lh "${DEPLOY_DIR}/app.jar"

          # 4) Reload unit files & restart the service (sudo allowed via sudoers)
          sudo -n systemctl daemon-reload
          sudo -n systemctl restart "${SERVICE}"

          # 5) Health check: treat 200/204/301/302/404 as "service up"
          echo "Waiting for app on http://localhost:8082${HEALTH_URL} ..."
          i=0
          until : ; do
            CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://localhost:8082${HEALTH_URL}")" || CODE=000
            echo "Health HTTP status: $CODE"
            case "$CODE" in
              200|204|301|302|404) echo "Service is up (HTTP $CODE)."; break ;;
            esac
            i=$((i+1))
            if [ "$i" -ge 30 ]; then
              echo "Service did not respond successfully in time. Last code: $CODE" >&2
              exit 1
            fi
            sleep 1
          done
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

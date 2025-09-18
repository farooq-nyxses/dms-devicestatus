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
        // POSIX /bin/sh compatible script (Ubuntu dash)
        sh '''
          set -eu

          # 1) Find the built JAR
          JAR="$(ls -1 target/*.jar | head -n1)"
          echo "Built JAR: $JAR"
          if [ ! -f "$JAR" ]; then
            echo "No jar built in target/" >&2
            exit 1
          fi

          # 2) Ensure deploy dir exists (no sudo, jenkins must own it)
          mkdir -p "${DEPLOY_DIR}"

          # 3) Copy JAR atomically with sane perms (0644) as app.jar (no sudo)
          install -m 0644 "$JAR" "${DEPLOY_DIR}/app.jar"
          ls -l "${DEPLOY_DIR}/app.jar"

          # 4) Reload units and restart ONLY this service (sudo allowed via sudoers)
          sudo -n systemctl daemon-reload
          sudo -n systemctl restart "${SERVICE}"

          # 5) Simple health wait (HTTP 200/302/403 treated as OK for HEAD)
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

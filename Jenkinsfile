pipeline {
  agent any

  options {
    timestamps()
  }

  environment {
    IMAGE_NAME     = "express-app"
    CONTAINER_NAME = "express-${BRANCH_NAME}"
    APP_PORT       = "3000"
  }

  stages {

    /* =========================
       CHECKOUT (TOUS LES CAS)
    ========================= */
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    /* =========================
       SETUP
    ========================= */
    stage('Setup') {
      steps {
        powershell 'docker --version'
      }
    }

    /* =========================
       BUILD (TOUS LES CAS)
    ========================= */
    stage('Build') {
      steps {
        powershell '''
          docker build -f DOCKERFILE -t %IMAGE_NAME% .
        '''
      }
    }

    /* =========================
       RUN + SMOKE
       - PR
       - DEV
    ========================= */
    stage('Run (Docker)') {
      when {
        anyOf {
          branch 'dev'
          expression { env.CHANGE_ID != null }
        }
      }
      steps {
        powershell '''
          if (docker ps -a --format "{{.Names}}" | findstr "%CONTAINER_NAME%") {
            docker rm -f %CONTAINER_NAME%
          }

          docker run -d ^
            --name %CONTAINER_NAME% ^
            -e REQUIRE_DB=false ^
            -p 3000:3000 ^
            %IMAGE_NAME%
        '''
      }
    }

    stage('Smoke Test') {
      when {
        anyOf {
          branch 'dev'
          expression { env.CHANGE_ID != null }
        }
      }
      steps {
        powershell '''
          Start-Sleep -Seconds 5
          .\\scripts\\smoke.ps1 3000
        '''
      }
    }

    /* =========================
       RELEASE BUILD (TAG)
    ========================= */
    stage('Release Build') {
      when {
        tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP"
      }
      steps {
        powershell '''
          docker build -f DOCKERFILE -t express-app:%TAG_NAME% .
          docker save express-app:%TAG_NAME% > release-%TAG_NAME%.tar
        '''
      }
    }

    /* =========================
       ARCHIVE
    ========================= */
    stage('Archive Artifacts') {
      steps {
        archiveArtifacts artifacts: '''
          release-*.tar,
          scripts/**,
          Jenkinsfile,
          DOCKERFILE
        ''', fingerprint: true
      }
    }
  }

  /* =========================
     CLEANUP
  ========================= */
  post {
    always {
      powershell '''
        docker rm -f %CONTAINER_NAME% 2>$null
      '''
    }
  }
}

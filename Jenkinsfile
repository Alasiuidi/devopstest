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
       CHECKOUT
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
       BUILD
    ========================= */
    stage('Build') {
      steps {
        powershell '''
          Write-Host "Building image: $env:IMAGE_NAME"
          docker build -f DOCKERFILE -t $env:IMAGE_NAME .
        '''
      }
    }

    /* =========================
       RUN (DEV + PR)
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
          if (docker ps -a --format "{{.Names}}" | Select-String "$env:CONTAINER_NAME") {
            docker rm -f $env:CONTAINER_NAME
          }

          docker run -d `
            --name $env:CONTAINER_NAME `
            -e REQUIRE_DB=false `
            -p 3000:3000 `
            $env:IMAGE_NAME
        '''
      }
    }

    /* =========================
       SMOKE TEST
    ========================= */
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
          Write-Host "Release build for tag: $env:TAG_NAME"
          docker build -f DOCKERFILE -t express-app:$env:TAG_NAME .
          docker save express-app:$env:TAG_NAME > release-$env:TAG_NAME.tar
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
        docker rm -f $env:CONTAINER_NAME 2>$null
      '''
    }
  }
}

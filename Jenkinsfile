pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()   // évite conflits Docker
  }

  environment {
    IMAGE_NAME     = "express-app"
    CONTAINER_NAME = "express-ci-${env.BUILD_NUMBER}"
  }

  stages {

    /* =========================
       1. CHECKOUT
    ========================= */
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    /* =========================
       2. SETUP
    ========================= */
    stage('Setup') {
      steps {
        powershell '''
          docker --version
        '''
      }
    }

    /* =========================
       3. BUILD
    ========================= */
    stage('Build') {
      steps {
        powershell '''
          Write-Host "Building Docker image"
          docker build -f DOCKERFILE -t $env:IMAGE_NAME .
        '''
      }
    }

    /* =========================
       4. RUN (DOCKER)
    ========================= */
    stage('Run (Docker)') {
      steps {
        powershell '''
          docker run -d `
            --name $env:CONTAINER_NAME `
            -e REQUIRE_DB=false `
            -P `
            $env:IMAGE_NAME
        '''
      }
    }

    /* =========================
       5. SMOKE TEST
    ========================= */
    stage('Smoke Test') {
      steps {
        powershell '''
          Start-Sleep -Seconds 5

          $portLine = docker port $env:CONTAINER_NAME 3000
          $PORT = ($portLine -split ":")[-1]

          Write-Host "Smoke test on port $PORT"
          .\\scripts\\smoke.ps1 $PORT
        '''
      }
    }

    /* =========================
       6. RELEASE (TAGS vX.Y.Z)
    ========================= */
    stage('Release Build') {
      when {
        tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP"
      }
      steps {
        powershell '''
          Write-Host "Release build for tag $env:GIT_TAG"
          docker tag $env:IMAGE_NAME $env:IMAGE_NAME:$env:GIT_TAG
        '''
      }
    }

    /* =========================
       7. ARCHIVE ARTIFACTS
    ========================= */
    stage('Archive Artifacts') {
      steps {
        archiveArtifacts artifacts: '''
          scripts/**,
          DOCKERFILE,
          Jenkinsfile
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
        if (docker ps -a --format "{{.Names}}" | Select-String "$env:CONTAINER_NAME") {
          docker rm -f $env:CONTAINER_NAME
        }
      '''
    }
  }
}

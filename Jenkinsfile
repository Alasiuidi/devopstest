pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
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
        powershell 'docker --version'
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
          Write-Host "Starting container"
          docker run -d `
            --name $env:CONTAINER_NAME `
            -e REQUIRE_DB=false `
            -p 3000:3000 `
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
          $maxAttempts = 10
          $delay = 2
          $url = "http://localhost:3000/"

          Write-Host "Running smoke test on $url"

          for ($i = 1; $i -le $maxAttempts; $i++) {
            try {
              $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3
              if ($response.StatusCode -eq 200) {
                Write-Host "SMOKE PASSED - API responding"
                exit 0
              }
            } catch {
              Write-Host "Attempt $i/$maxAttempts - API not ready"
            }
            Start-Sleep -Seconds $delay
          }

          Write-Host "SMOKE FAILED"
          exit 1
        '''
      }
    }

    /* =========================
       6. RELEASE BUILD (TAG)
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
       7. ARCHIVE
       ========================= */
    stage('Archive Artifacts') {
      steps {
        archiveArtifacts artifacts: '''
          DOCKERFILE,
          Jenkinsfile,
          scripts/**
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
        Write-Host "Cleaning up container"
        docker rm -f $env:CONTAINER_NAME 2>$null
      '''
    }
  }
}

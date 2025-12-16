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

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Setup') {
      steps {
        powershell 'docker --version'
      }
    }

    stage('Build') {
      steps {
        powershell '''
          Write-Host "Building Docker image"
          docker build -f DOCKERFILE -t $env:IMAGE_NAME .
        '''
      }
    }

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

    stage('Smoke Test') {
      steps {
        powershell '''
          Start-Sleep -Seconds 5
          .\\scripts\\smoke.ps1 $env:CONTAINER_NAME
        '''
      }
    }

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

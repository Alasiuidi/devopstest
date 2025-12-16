pipeline {
  agent any

  options {
    timestamps()
  }

  triggers {
    pollSCM('H/2 * * * *') // Jenkins local
  }

  environment {
    IMAGE_BASE = "express-app"
  }

  stages {

    /* =====================
       CHECKOUT
    ===================== */
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    /* =====================
       SETUP
    ===================== */
    stage('Setup') {
      steps {
        powershell '''
          docker --version
        '''
      }
    }

    /* =====================
       BUILD IMAGE
    ===================== */
    stage('Build') {
      steps {
        powershell '''
          docker build -f DOCKERFILE -t $env:IMAGE_BASE:$env:BUILD_NUMBER .
        '''
      }
    }

    /* =====================
       RUN (feature + dev)
    ===================== */
    stage('Run (Docker)') {
      when {
        anyOf {
          branch 'dev'
          branch 'feature/*'
        }
      }
      steps {
        powershell '''
          $container="app-$env:BUILD_NUMBER"

          docker rm -f $container 2>$null

          docker run -d `
            --name $container `
            -e REQUIRE_DB=false `
            -P `
            $env:IMAGE_BASE:$env:BUILD_NUMBER
        '''
      }
    }

    /* =====================
       SMOKE TEST
    ===================== */
    stage('Smoke Test') {
      when {
        anyOf {
          branch 'dev'
          branch 'feature/*'
        }
      }
      steps {
        powershell '''
          Start-Sleep -Seconds 5

          $container="app-$env:BUILD_NUMBER"
          $portLine = docker port $container 3000
          $PORT = ($portLine -split ":")[-1]

          .\\scripts\\smoke.ps1 $PORT
        '''
      }
    }

    /* =====================
       RELEASE (TAG)
    ===================== */
    stage('Release Build') {
      when {
        buildingTag()
      }
      steps {
        powershell '''
          docker build -f DOCKERFILE -t $env:IMAGE_BASE:$env:GIT_TAG_NAME .
        '''
      }
    }

    /* =====================
       ARCHIVE
    ===================== */
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

  /* =====================
     CLEANUP
  ===================== */
  post {
    always {
      powershell '''
        docker ps -a --format "{{.Names}}" | Where-Object { $_ -like "app-*" } | ForEach-Object {
          docker rm -f $_
        }
      '''
    }
  }
}
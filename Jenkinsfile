pipeline {
  agent {
        docker {
            image 'node:10.9.0-jessie'
        }
    }
  stages {
    stage('build-solidity-docs') {
      steps {
        sh 'node -v'
      }
    }
    stage('deploy-to-gh-pages') {
      steps {
        sh 'npm -v'
      }
    }
  }
}

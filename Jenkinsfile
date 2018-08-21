pipeline {
  agent {
        docker {
            image 'maven:3-alpine'
            args '-v $HOME/.m2:/root/.m2'
        }
    }
  stages {
    stage('build-solidity-docs') {
      steps {
        sh 'solidity-docgen ./ contracts/ ./docs'
      }
    }
    stage('deploy-to-gh-pages') {
      steps {
        sh 'cd docs/website && npm install && npm run publish-gh-pages'
      }
    }
  }
}

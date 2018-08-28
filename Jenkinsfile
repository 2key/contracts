pipeline {
  agent {
        docker {
            image 'shlomiz2key/runners:deployer-1.0.5'
            args '-u $JENKINS_USER:$JENKINS_USER'
        }
    }
  stages {
    stage('build-solidity-docs') {
      steps {
        sh 'npm install -g solidity-docgen'
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

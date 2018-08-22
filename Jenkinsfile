pipeline {
  agent {
        docker {
            image 'shlomiz2key/runners'
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
        sh 'cd docs/website && npm run publish-gh-pages'
      }
    }
  }
}

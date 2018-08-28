pipeline {
  agent {
        docker {
            image 'shlomiz2key/runners:deployer-1.0.6'
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

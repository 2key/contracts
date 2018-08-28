
pipeline {
  agent {
    docker {
      image 'shlomiz2key/runners:deployer-1.0.8'
      reuseNode true
      args '-e npm_config_cache=npm-cache -e HOME=.'
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

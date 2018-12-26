pipeline {
  agent {
    docker {
      image 'shlomiz2key/runners:deployer-1.0.10'
      reuseNode true
      args '-e npm_config_cache=npm-cache -e HOME=.'
    }
  }
  environment {
        GITHUB_TOKEN = credentials('github')
  }
  stages {
    stage('build-solidity-docs') {
      steps {
        sh 'solidity-docgen ./ contracts/ ./documentation'
      }
    }
    stage('deploy-to-gh-pages') {
      steps {
        sh 'cd documentation/website && npm install && npm run build && yarn run publish-gh-pages'
      }
    }
  }
}

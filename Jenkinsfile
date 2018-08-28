pipeline {
  agent {
        docker {
            image 'shlomiz2key/runners:deployer-1.0.6'
            reuseNode true
        }
    }
  environment {
    /* Override the npm cache directory to avoid: EACCES: permission denied, mkdir '/.npm' */
    npm_config_cache = 'npm-cache',
    /* set home to our current directory because other bower
    * nonsense breaks with HOME=/, e.g.:
    * EACCES: permission denied, mkdir '/.config'
    */
    HOME = '.'
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

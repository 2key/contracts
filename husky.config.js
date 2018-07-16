module.exports = {
  husky: {
    hooks: {
      'pre-commit': 'echo HUSKY $HUSKY_GIT_PARAMS',
      '!pre-commit': 'npm run sol -- commit',
      'pre-push': 'npm run sol -- push',
    }  
  },
  hooks: {
    'pre-commit': 'echo HUSKY $HUSKY_GIT_PARAMS',
    '!pre-commit': 'npm run sol -- commit',
    'pre-push': 'npm run sol -- push',
  }
};
const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const ProgressBarPlugin = require('progress-bar-webpack-plugin');

const libraryName = 'twokey-protocol';

const config = {
  entry: './2key-protocol/index.ts',
  devtool: 'source-map',
  output: {
    path: path.join(__dirname, 'build', '2key-protocol'),
    filename: 'index.js',
    library: libraryName,
    libraryTarget: 'umd',
    umdNamedDefine: true,
  },
  module: {
    rules: [
      {
        test: /(\.tsx|\.ts)$/,
        // loader: 'awesome-typescript-loader',
        loader: 'ts-loader',
        // exclude: /node_modules/,
        // query: {
        //   declaration: true,
        // }
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.js'],
  },
  plugins: [
    new UglifyJsPlugin({
      sourceMap: true,
    }),
    new ProgressBarPlugin(),
  ],
};

module.exports = config;

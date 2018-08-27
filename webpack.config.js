const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const ProgressBarPlugin = require('progress-bar-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

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
        loader: 'ts-loader',
      },
    ],
  },
  resolve: {
    extensions: ['.ts', '.js'],
  },
  target: 'node',
  externals: [nodeExternals()],
  plugins: [
    new UglifyJsPlugin({
      sourceMap: true,
    }),
    new ProgressBarPlugin(),
  ],
};

module.exports = config;

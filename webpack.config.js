const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const ProgressBarPlugin = require('progress-bar-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

const libraryName = 'twokey-protocol';

const config = {
  entry: './2key-protocol/src/index.ts',
  devtool: 'source-map',
  output: {
    path: path.join(__dirname, '2key-protocol', 'dist'),
    filename: 'index.js',
    library: libraryName,
    libraryTarget: 'commonjs2',
    umdNamedDefine: true,
  },
  module: {
    rules: [
      {
        test: /(\.tsx|\.ts)$/,
        loader: 'ts-loader',
        exclude: /test/,
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
      sourceMap: false,
      uglifyOptions: {
        compress: {
          drop_console: true,
        }
      }
    }),
    new ProgressBarPlugin(),
  ],
};

module.exports = config;

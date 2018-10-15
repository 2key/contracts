const ProgressBarPlugin = require('progress-bar-webpack-plugin');
const nodeExternals = require('webpack-node-externals');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const webpack = require('webpack');

const config = {
  entry: './2key-protocol/test/webapp.ts',
  devtool: 'source-map',
  output: {
    publicPath: '/',
    globalObject: 'this', // hot reload has a bug with setting the global object in webworkers
    filename: '[name].js',
  },
  devServer: {
    hot: true,
    contentBase: './public',
    historyApiFallback: true,
    inline: true,
    overlay: true,
    port: 3003,
    watchContentBase: true,
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
  plugins: [
    new ProgressBarPlugin(),
    new webpack.HotModuleReplacementPlugin(),
    new HtmlWebpackPlugin({
      inject: true,
      template: '2key-protocol/test/index.html',
    }),

  ],
};

module.exports = config;

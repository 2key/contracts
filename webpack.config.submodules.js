const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const ProgressBarPlugin = require('progress-bar-webpack-plugin');

const config = {
  entry: {
    acquisition: './2key-protocol/src/acquisition/index.ts',
    donation: './2key-protocol/src/donation/index.ts',
    cpc: './2key-protocol/src/cpc/index.ts'
  },
  devtool: 'source-map',
  output: {
    path: path.join(__dirname, '2key-protocol', 'dist', 'submodules'),
    filename: '[name].js',
    library: ['TwoKeyProtocol', '[name]'],
    libraryTarget: 'umd',
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
  plugins: [
    new UglifyJsPlugin({
      sourceMap: true,
      uglifyOptions: {
        sourceMap: true,
        compress: {
          drop_console: true,
        }
      }
    }),
    new ProgressBarPlugin(),
  ],
};

module.exports = config;

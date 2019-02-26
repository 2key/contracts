const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const ProgressBarPlugin = require('progress-bar-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

const libraryName = {
  acquisition: 'Acquisition',
    donation: 'Donation'
};

const config = {
  entry: {
    acquisition: './2key-protocol/src/acquisition/index.ts',
    dao: './2key-protocol/src/decentralizedNation/index.ts',
    donation: './2key-protocol/src/donation/index.ts'
  },
  devtool: 'none',
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
  // target: 'node',
  // externals: [nodeExternals()],
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

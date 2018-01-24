const path = require('path');
const webpack = require('webpack');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');
// const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: './app/javascripts/app.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'app.js'
  },
  plugins: [
    // new HtmlWebpackPlugin({
    //             template: 'app/index.html'
    //         }),
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery'
    }),
    // Copy our app's index.html to the dist folder.
    new CopyWebpackPlugin([
      { from: './app/index.html', to: "index.html" },
      { from: './app/images/clippy.svg', to: "clippy.svg" },
    ]),
    new CleanWebpackPlugin(['dist'])
  ],
  module: {
    rules: [
      {
       test: /\.css$/,
       use: [ 'style-loader', 'css-loader' ]
      },
      // {
      //   test: /\.md$/,
      //   use: ['html-loader', 'markdown-loader']
      // },
      //
      //   {
      //       test: /\.(html)$/,
      //       use: {
      //           loader: 'html-loader',
      //       }
      //   },
        {
            test: /\.(html)$/,
            use: [{
                loader: 'file-loader',
                options: {
                  name: '[name].html'
                }
            }],
            exclude: path.resolve(__dirname, 'index.html')
        },
        {
            test: /\.(md)$/,
            use: [
                {
                    loader: 'file-loader',
                    options: {
                      name: '[name].html'
                    }
                },
                {
                    loader: 'markdown-loader',
                },
        //         {
        //             loader: 'html-loader!markdown-loader!file-loader',
        //             options: {
        //               name: '[name].html'
        //             }
        //         }
            ],
        },


    ],
    loaders: [
      { test: /\.json$/, use: 'json-loader' },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        loader: 'babel-loader',
        query: {
          presets: ['es2015'],
          plugins: ['transform-runtime']
        },
      },
    ]
  },
  devServer: {
    host: '0.0.0.0',
    disableHostCheck: true
  },
}

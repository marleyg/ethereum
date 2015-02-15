module.exports = {
  loaders: [
    { test: /\.coffee$/, loader: "coffee-loader" },
    { test: /\.scss$/, loader: "style!css!sass" }
  ],
  //entry: './javascripts/script.coffee',
  entry: './javascripts/main.js',
  output: {
    filename: './javascripts/app.js'
  }
};

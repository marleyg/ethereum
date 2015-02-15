var watch = require('node-watch');

var filter = function(pattern, fn) {
  return function(filename) {
    if (pattern.test(filename)) {
      fn(filename);
    }
  }
}

watch('.', filter(/\.coffee|haml|sass$/, function(filename) {
  console.log(filename, ' changed.');
}));

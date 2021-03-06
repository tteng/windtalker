// Generated by CoffeeScript 1.6.1
(function() {
  var StockSZ, WindTalker, settings, stock_sz,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  WindTalker = require('./wind_talker');

  settings = require('../config/settings');

  StockSZ = (function(_super) {

    __extends(StockSZ, _super);

    function StockSZ() {
      return StockSZ.__super__.constructor.apply(this, arguments);
    }

    StockSZ.prototype.redisKey = function(ticker) {
      var key;
      if (ticker) {
        return key = "" + settings.redisNamespace + ":SZ:" + ticker;
      } else {
        return null;
      }
    };

    return StockSZ;

  })(WindTalker);

  stock_sz = new StockSZ('SZ', settings.host, settings.port);

  process.on('message', function(msg) {
    console.log("[CHILD][SZ] RECEIVED " + msg);
    if (msg === 'start') {
      stock_sz.listen();
    } else if (msg === 'download') {
      stock_sz.downloadAndSave('SZ');
    }
    return process.send("[CHILD][SZ] process#" + process.pid + " copy " + msg + ".");
  });

  process.on('exit', function() {
    console.log('EXIT ....');
    stock_sz.stop();
    return process.send("[CHILD][SZ] process#" + process.pid + " exit.");
  });

  process.on('error', function(err) {
    console.log('[CHILD][SZ] Internal Error #{err} Occured.');
    process.send(err);
    return process.exit(1);
  });

  process.on('SIGTERM', function() {
    console.log('SIGTERM ....');
    process.send("[CHILD][SZ] process#" + process.pid + " terminated.");
    return process.exit(0);
  });

}).call(this);

// Generated by CoffeeScript 1.6.1
(function() {
  var WindTalker, fs, net, os, settings, zlib,
    _this = this;

  fs = require('fs');

  zlib = require('zlib');

  net = require('net');

  os = require('os');

  settings = require('../config/settings');

  WindTalker = (function() {

    function WindTalker(channel, host, port) {
      var _ref,
        _this = this;
      this.channel = channel;
      this.host = host;
      this.port = port;
      this.analyze_data = function(cursor, raw_buf) {
        return WindTalker.prototype.analyze_data.apply(_this, arguments);
      };
      this.greeting = "m=" + this.channel + ";u=" + settings.username + ";p=" + settings.password + ";EX_HEAD=a8b9c0d1;EX_SIZE=1;";
      console.log("greeting: " + this.greeting);
      this.client = new net.Socket();
      this.delta = new Buffer(0);
      _ref = [0, 0, false], this.message_size = _ref[0], this.head = _ref[1], this.found_head = _ref[2];
      console.log("The cpu endian is " + (os.endianness()));
    }

    WindTalker.prototype.listen = function() {
      var _this = this;
      this.client.connect(this.port, this.host, function() {
        console.log("Connect to " + _this.host + ":" + _this.port);
        return _this.client.write(_this.greeting);
      });
      return this.client.on('data', function(data) {
        _this.delta = Buffer.concat([_this.delta, data]);
        if (!_this.found_head) {
          if (!(_this.delta.length < 16)) {
            _this.detect_head(_this.delta);
          }
        }
        if (_this.found_head && _this.message_size === 0) {
          console.log("delta length: " + _this.delta.length + ", head: " + _this.head);
          console.log("detecting message size ....");
          _this.detect_message_size();
        }
        if (_this.message_size > 0) {
          if (_this.received_complete_message()) {
            console.log("@delta_length: " + _this.delta.length + ", received enougth message");
            return _this.split_buffer_and_decode();
          }
        }
      });
    };

    WindTalker.prototype.received_complete_message = function() {
      return this.delta.length >= this.head + 4 + 4 + this.message_size;
    };

    WindTalker.prototype.split_buffer_and_decode = function() {
      var wild_buf, _ref;
      wild_buf = new Buffer(this.message_size);
      wild_buf.fill(0);
      this.delta.copy(wild_buf, 0, this.head + 4 + 4, this.head + 4 + 4 + this.message_size);
      this.delta = this.delta.slice(this.head + 4 + 4 + this.message_size, this.delta.length);
      _ref = [0, 0, false], this.message_size = _ref[0], this.head = _ref[1], this.found_head = _ref[2];
      return this.decode_buf(wild_buf, 0);
    };

    WindTalker.prototype.decode_buf = function(buf, cursor) {
      var chunk_size, raw_data_buf, raw_data_size, _ref;
      if (cursor >= buf.length) {
        return;
      }
      chunk_size = buf.readUInt32LE(cursor);
      raw_data_size = buf.readUInt32LE(cursor + 4);
      console.log("chunk_size: " + (chunk_size - 4) + ", raw_data_size: " + raw_data_size + ", valid: " + ((_ref = raw_data_size % 156 === 0) != null ? _ref : {
        "true": false
      }));
      raw_data_buf = new Buffer(chunk_size - 4);
      raw_data_buf.fill(0);
      buf.copy(raw_data_buf, 0, cursor + 4 + 4, cursor + 4 + 4 + chunk_size - 4);
      this.inflate_and_iterate_buf(raw_data_buf, raw_data_size);
      cursor = cursor + 4 + 4 + chunk_size - 4;
      return this.decode_buf(buf, cursor);
    };

    WindTalker.prototype.inflate_and_iterate_buf = function(raw_buf, raw_data_size) {
      var _this = this;
      console.log("raw buf size: " + raw_buf.length);
      return zlib.inflate(raw_buf, function(error, result) {
        if (error) {
          console.log("[Error] inflate data failed.");
          throw error;
        } else {
          if (result.length === raw_data_size) {
            console.log("[Info] inflate succeed.");
            if (result.length % 156 === 0) {
              return _this.analyze_data(0, result);
            } else {
              return consloe.log("[Error] invalid buffer size");
            }
          }
        }
      });
    };

    WindTalker.prototype.analyze_data = function(cursor, raw_buf) {
      var buf, contract, data, feature_price, holding, i, latest_deal, m_fAmount, m_fHigh, m_fLastClose, m_fLow, m_fNewPrice, m_fOpen, m_fVolume, market, result, time_t, total_deal, val;
      if (cursor >= raw_buf.length) {
        console.log("process finished.");
        return;
      }
      console.log("analyzing...");
      data = new Buffer(156);
      data.fill(0);
      result = '';
      buf = raw_buf.copy(data, 0, cursor, cursor + 156);
      time_t = data.readUInt32LE(0);
      console.log("time_t: " + time_t);
      result += "" + time_t + ",";
      market = data.toString('ascii', 4, 15);
      console.log("mar: " + market);
      result += "" + market + ",";
      contract = data.toString('ascii', 16, 31);
      console.log("contract: " + contract);
      result += "" + contract + ",";
      total_deal = data.readFloatLE(32);
      console.log("total_deal: " + total_deal);
      result += "" + total_deal + ",";
      latest_deal = data.readFloatLE(36);
      console.log("latest_deal: " + latest_deal);
      result += "" + latest_deal + ",";
      holding = data.readFloatLE(40);
      console.log("holding: " + holding);
      result += "" + holding + ",";
      feature_price = data.readFloatLE(44);
      console.log("feature_price: " + feature_price);
      result += "" + feature_price + ",";
      m_fLastClose = data.readFloatLE(48);
      console.log("m_fLastClose: " + m_fLastClose);
      result += "" + m_fLastClose + ",";
      m_fOpen = data.readFloatLE(52);
      console.log("m_fOpen: " + m_fOpen);
      result += "" + m_fOpen + ",";
      m_fHigh = data.readFloatLE(56);
      console.log("m_fHigh: " + m_fHigh);
      result += "" + m_fHigh + ",";
      m_fLow = data.readFloatLE(60);
      console.log("m_fLow: " + m_fLow);
      result += "" + m_fLow + ",";
      m_fNewPrice = data.readFloatLE(64);
      console.log("m_fNewPrice: " + m_fNewPrice);
      result += "" + m_fNewPrice + ",";
      m_fVolume = data.readFloatLE(68);
      console.log("m_fVolume: " + m_fVolume);
      result += "" + m_fVolume + ",";
      m_fAmount = data.readFloatLE(72);
      console.log("m_fAmount: " + m_fAmount);
      result += "" + m_fAmount + ",[";
      i = 0;
      while (i < 5) {
        val = data.readFloatLE(76 + i * 4);
        result += "" + val;
        if (i !== 4) {
          result += ",";
        }
        i += 1;
      }
      result += "],[";
      i = 0;
      while (i < 5) {
        val = data.readFloatLE(96 + i * 4);
        result += "" + val;
        if (i !== 4) {
          result += ",";
        }
        i += 1;
      }
      result += "],[";
      i = 0;
      while (i < 5) {
        val = data.readFloatLE(116 + i * 4);
        result += "" + val;
        if (i !== 4) {
          result += ",";
        }
        i += 1;
      }
      result += "],[";
      i = 0;
      while (i < 5) {
        val = data.readFloatLE(136 + i * 4);
        result += "" + val;
        if (i !== 4) {
          result += ",";
        }
        i += 1;
      }
      result += "]";
      console.log("result: " + result);
      result = null;
      raw_buf = raw_buf.slice(cursor + 156, raw_buf.length);
      cursor = 0;
      return this.analyze_data(cursor, raw_buf);
    };

    WindTalker.prototype.detect_head = function() {
      var bite, i, _i, _len, _ref, _results;
      _ref = this.delta;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        bite = _ref[i];
        if (this.is_head(this.delta, i)) {
          this.head = i;
          this.found_head = true;
          console.log("head is: " + this.head);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    WindTalker.prototype.detect_message_size = function() {
      if (this.delta.length >= this.head + 4 + 4) {
        console.log("load enough data to read message size");
        this.message_size = this.delta.readUInt32LE(this.head + 4);
        return console.log("message size: " + this.message_size);
      }
    };

    WindTalker.prototype.is_head = function(buff, idx) {
      var bite, result;
      result = false;
      bite = buff[idx];
      if (bite && bite.toString('16').toLowerCase() === 'd1') {
        if (buff[idx + 1] && buff[idx + 1].toString('16').toLowerCase() === 'c0') {
          if (buff[idx + 2] && buff[idx + 2].toString('16').toLowerCase() === 'b9') {
            if (buff[idx + 3] && buff[idx + 3].toString('16').toLowerCase() === 'a8') {
              result = true;
            }
          }
        }
      }
      return result;
    };

    WindTalker.prototype.stop = function() {
      return this.client.destroy();
    };

    return WindTalker;

  })();

  module.exports = WindTalker;

}).call(this);
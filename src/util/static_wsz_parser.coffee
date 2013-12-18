fs    = require 'fs'
os    = require 'os'
zlib  = require 'zlib'
settings = require '../config/settings'
redis    = require('../db/redis_util').createClient()
WindTalker = require '../models/wind_talker'

class StaticWszParser

  constructor: (@filePath, @market, @saveFunc) ->

  parse: ->
    fs.open @filePath, 'r', (err,fd) =>
      if err
        console.log "[Error] read origin data failed"
      else
        iterate_data_file = @iterate_data_file
        fs.stat @filePath, (err, stat) =>
          if err
            console.log "[Error] get origin file size failed"
          else
            file_size = stat.size
            console.log "origin file size: #{file_size}"
            @iterate_data_file fd, 0, file_size

  iterate_data_file: (fd, cursor, file_size) ->
    if cursor >= file_size
      console.log "reach file end, that's all."
      return
    meta_buf = new Buffer 8
    meta_buf.fill 0
    fs.read fd, meta_buf, offset=0, length=8, position=cursor, (err, bytesRead, buffer) =>
      chunk_size = meta_buf.readUInt32LE 0
      raw_data_size = meta_buf.readUInt32LE 4
      data_buf = new Buffer chunk_size
      data_buf.fill 0
      console.log "cursor: #{cursor}, chunk_size: #{chunk_size-4}, raw_data_size: #{raw_data_size}, copy index from #{cursor+4+4} to #{cursor+4+4+chunk_size-4-1}"
      iterate_buf = @iterate_buf
      fs.read fd, data_buf, 0, chunk_size-4, cursor+4+4, (err, bytesRead, buffer) =>
        @iterate_buf data_buf, raw_data_size
      cursor = cursor+4+4+chunk_size-4
      @iterate_data_file fd, cursor, file_size

  iterate_buf: (raw_buf, raw_data_size) ->
    console.log "raw buf size: #{raw_buf.length}"
    zlib.inflate raw_buf, (error, result) => 
      if error
        console.log "[Error] inflate data failed."
        throw error
      else
        if result.length is raw_data_size
          console.log "[Info] inflate succeed."
          if result.length % 156 is 0
            @analyze_data 0, result
          else
            consloe.log "[Error] invalid buffer size" 

  analyze_data: (cursor, raw_buf) =>
    while cursor < raw_buf.length
      data = new Buffer 156
      data.fill 0
      result = ''
      buf = raw_buf.copy data, 0, cursor, cursor+156

      time_t = data.readUInt32LE(0)         
      result += "#{time_t},"

      for i in [4..15]
        break if data[i] is 0 

      market = data.toString('ascii', 4, i)  #market ends with unicode 0, if not truncate it, redis can't save it as a common string key 
      result += "#{market},"

      for j in [16..31]
        break if data[j] is 0
      contract = data.toString 'ascii', 16, j
      result += "#{contract},"

      total_deal = data.readFloatLE(32)
      result += "#{total_deal},"

      latest_deal = data.readFloatLE(36)  
      result += "#{latest_deal},"

      holding = data.readFloatLE(40)
      result += "#{holding},"

      feature_price = data.readFloatLE(44)
      result += "#{feature_price},"

      m_fLastClose = data.readFloatLE(48)
      result += "#{m_fLastClose},"

      m_fOpen = data.readFloatLE(52)
      result += "#{m_fOpen},"

      m_fHigh = data.readFloatLE(56)
      result += "#{m_fHigh},"

      m_fLow = data.readFloatLE(60)
      result += "#{m_fLow},"

      m_fNewPrice = data.readFloatLE(64) 
      result += "#{m_fNewPrice},"

      m_fVolume = data.readFloatLE(68) 
      result += "#{m_fVolume},"

      m_fAmount = data.readFloatLE(72) 
      result += "#{m_fAmount},["

      i = 0
      buyBids = []                                #申买价
      while i < 5
        val = data.readFloatLE(76+i*4) 
        buyBids.push val
        result += "#{val}"
        result += "," unless i == 4
        i+=1
      result += "],["

      i = 0
      buyAmount = []                              #申买量
      while i < 5
        val = data.readFloatLE(96+i*4) 
        buyAmount.push val
        result += "#{val}"
        result += "," unless i == 4
        i+=1
      result += "],["

      i = 0
      sellBids = []                               #申卖价
      while i < 5
        val = data.readFloatLE(116+i*4) 
        sellBids.push val
        result += "#{val}"
        result += "," unless i == 4
        i+=1
      result += "],["

      i = 0
      sellAmount = []                              #申卖量
      while i < 5
        val = data.readFloatLE(136+i*4) 
        sellAmount.push val
        result += "#{val}"
        result += "," unless i == 4
        i+=1
      result += "]"

      console.log "result: #{result}"
      result = null

      @saveFunc time_t, market, m_fLastClose, m_fOpen, m_fHigh, m_fLow, m_fNewPrice, m_fVolume, m_fAmount
      cursor = cursor + 156

  redisKey: (ticker) ->
    if ticker
      key = "#{settings.redisNamespace}:#{@market}Close:#{ticker}"
    else
      null

module.exports = StaticWszParser

fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'
settings = require '../config/settings'
redis    = require('../db/redis_util').createClient()

class WindTalker

  constructor: (@channel, @host, @port) ->
    @greeting  = "m=#{@channel};u=#{settings.username};p=#{settings.password};EX_HEAD=a8b9c0d1;EX_SIZE=1;"
    @client    = new net.Socket()
    @delta     = new Buffer 0
    [@message_size, @head, @found_head] = [0, 0, false]

  listen: ->
    @client.connect @port, @host, =>
      @client.write @greeting

    @client.on 'data', (data) =>
      @delta = Buffer.concat [@delta, data]
      unless @found_head
        unless @delta.length < 16
          @detect_head @delta  
      
      if @found_head and @message_size is 0
        @detect_message_size()

      if @message_size > 0
        if @received_complete_message()
          @split_buffer_and_decode()

  received_complete_message: ->
    @delta.length >= @head + 4 + 4 + @message_size 

  split_buffer_and_decode: -> 
    wild_buf = new Buffer @message_size   
    wild_buf.fill 0
    @delta.copy wild_buf, 0, @head+4+4, @head+4+4+@message_size
    @delta = @delta.slice @head+4+4+@message_size, @delta.length 
    [@message_size, @head, @found_head] = [0, 0, false]
    @decode_buf wild_buf, 0

  decode_buf: (buf, cursor) ->
    return if cursor >= buf.length
    chunk_size = buf.readUInt32LE cursor
    raw_data_size = buf.readUInt32LE cursor+4
    try
      raw_data_buf = new Buffer chunk_size-4 
      raw_data_buf.fill 0
    catch error
      console.log "[Error][AllocateMemoryFailed]"
      raw_data_buf = null
    
    if raw_data_buf 
      buf.copy raw_data_buf, 0, cursor+4+4, cursor+4+4+chunk_size-4
      @inflate_and_iterate_buf raw_data_buf, raw_data_size
      cursor = cursor+4+4+chunk_size-4
      @decode_buf buf, cursor

  inflate_and_iterate_buf: (raw_buf, raw_data_size) ->
    zlib.inflate raw_buf, (error, result) => 
      if error
        throw error
      else
        if result.length is raw_data_size
          if result.length % 156 is 0
            @analyze_data 0, result
          else
            consloe.log "[Error] invalid buffer size" 

  detect_head: ->
    for bite, i in @delta 
      if @is_head(@delta, i)
        @head = i 
        @found_head = true
        console.log "head is: #{@head}"
        break

  detect_message_size: ->
    if @delta.length >= @head + 4 + 4  #0xA8B9C0D1: 4bytes, MSG_SIZE: 4bytes
      console.log "load enough data to read message size"
      @message_size = @delta.readUInt32LE @head+4
      console.log "message size: #{@message_size}" 

  #helper, detect stream head.
  is_head: (buff, idx) ->
    result = false
    bite = buff[idx]
    if bite and bite.toString('16').toLowerCase() is 'd1'
      if buff[idx+1] and buff[idx+1].toString('16').toLowerCase() is 'c0'
        if buff[idx+2] and buff[idx+2].toString('16').toLowerCase() is 'b9'
          if buff[idx+3] and buff[idx+3].toString('16').toLowerCase() is 'a8'
            result = true
    result

  stop: ->
    @client.destroy()

  analyze_data: (cursor, raw_buf) =>
    if cursor >= raw_buf.length  
      console.log "process finished." 
      return
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

    @saveToDb time_t, market, m_fLastClose, m_fOpen, m_fHigh, m_fLow, m_fNewPrice, m_fVolume, m_fAmount

    #console.log "result: #{result}"
    result = null

    raw_buf = raw_buf.slice cursor+156, raw_buf.length
    cursor = 0
    @analyze_data cursor, raw_buf

  saveToDb: (time, ticker, fLastClose, fOpen, fHigh, fLow, fNewPrice, fVolume, fAmount) ->
    #console.log "#{time}, #{ticker}, #{fLastClose}, #{fOpen}, #{fHigh}, #{fLow}, #{fNewPrice}, #{fVolume}, #{fAmount}"
    if key = @redisKey ticker
      redis.hmset(key, {
                        "t":       time, 
                        "close":   fLastClose, 
                        "open":    fOpen, 
                        "high":    fHigh, 
                        "low":     fLow, 
                        "current": fNewPrice, 
                        "volume":  fVolume, 
                        "amount":  fAmount
                       }, (err, result) ->
                            console.log key if result
                            console.error "[REDIS][ERROR] update #{corresponding_key} failed for #{err}." if err
                 )

module.exports = WindTalker

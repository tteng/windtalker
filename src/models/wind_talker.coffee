fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'
settings = require '../config/settings'

class WindTalker

  constructor: (@channel, @host, @port) ->
    @greeting  = "m=#{@channel};u=#{settings.username};p=#{settings.password};EX_HEAD=a8b9c0d1;EX_SIZE=1;"
    console.log "greeting: #{@greeting}"
    @client    = new net.Socket()
    @delta     = new Buffer 0
    [@message_size, @head, @found_head] = [0, 0, false]
    console.log "The cpu endian is #{os.endianness()}" 

  listen: ->
    @client.connect @port, @host, =>
      console.log "Connect to #{@host}:#{@port}"
      @client.write @greeting

    @client.on 'data', (data) =>
      @delta = Buffer.concat [@delta, data]
      unless @found_head
        unless @delta.length < 16
          @detect_head @delta  
      
      if @found_head and @message_size is 0
        console.log "delta length: #{@delta.length}, head: #{@head}"
        console.log "detecting message size ...."
        @detect_message_size()

      if @message_size > 0
        if @received_complete_message()
          console.log "@delta_length: #{@delta.length}, received enougth message"
          @split_buffer_and_decode()
          #@client.destroy()

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
    console.log "chunk_size: #{chunk_size-4}, raw_data_size: #{raw_data_size}, valid: #{(raw_data_size % 156 is 0) ? true :false}"    
    raw_data_buf = new Buffer chunk_size-4 
    raw_data_buf.fill 0
    buf.copy raw_data_buf, 0, cursor+4+4, cursor+4+4+chunk_size-4
    @inflate_and_iterate_buf raw_data_buf, raw_data_size
    cursor = cursor+4+4+chunk_size-4
    @decode_buf buf, cursor

  inflate_and_iterate_buf: (raw_buf, raw_data_size) ->
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
    if cursor >= raw_buf.length  
      console.log "process finished." 
      return
    console.log "analyzing..."
    data = new Buffer 156
    data.fill 0
    result = ''
    buf = raw_buf.copy data, 0, cursor, cursor+156

    time_t = data.readUInt32LE(0)         
    console.log "time_t: #{time_t}"
    result += "#{time_t},"

    market = data.toString 'ascii', 4, 15
    console.log "mar: #{market}"
    result += "#{market},"

    contract = data.toString 'ascii', 16, 31 
    console.log "contract: #{contract}"
    result += "#{contract},"

    total_deal = data.readFloatLE(32)
    console.log "total_deal: #{total_deal}"
    result += "#{total_deal},"

    latest_deal = data.readFloatLE(36)  
    console.log "latest_deal: #{latest_deal}"
    result += "#{latest_deal},"

    holding = data.readFloatLE(40)
    console.log "holding: #{holding}"
    result += "#{holding},"

    feature_price = data.readFloatLE(44)
    console.log "feature_price: #{feature_price}"
    result += "#{feature_price},"

    m_fLastClose = data.readFloatLE(48)
    console.log "m_fLastClose: #{m_fLastClose}"
    result += "#{m_fLastClose},"

    m_fOpen = data.readFloatLE(52)
    console.log "m_fOpen: #{m_fOpen}"
    result += "#{m_fOpen},"

    m_fHigh = data.readFloatLE(56)
    console.log "m_fHigh: #{m_fHigh}"
    result += "#{m_fHigh},"

    m_fLow = data.readFloatLE(60)
    console.log "m_fLow: #{m_fLow}"
    result += "#{m_fLow},"

    m_fNewPrice = data.readFloatLE(64) 
    console.log "m_fNewPrice: #{m_fNewPrice}"
    result += "#{m_fNewPrice},"

    m_fVolume = data.readFloatLE(68) 
    console.log "m_fNewPrice: #{m_fVolume}"
    result += "#{m_fVolume},"

    m_fAmount = data.readFloatLE(72) 
    console.log "m_fAmount: #{m_fAmount}"
    result += "#{m_fAmount},["

    i = 0
    while i < 5
      val = data.readFloatLE(76+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(96+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(116+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(136+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "]"

    console.log "result: #{result}"
    result = null

    raw_buf = raw_buf.slice cursor+156, raw_buf.length
    cursor = 0
    @analyze_data cursor, raw_buf



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

w = new WindTalker('IX', settings.host, settings.port)
w.listen()

  

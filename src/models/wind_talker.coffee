fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'
settings = require '../config/settings'

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
    raw_data_buf = new Buffer chunk_size-4 
    raw_data_buf.fill 0
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

module.exports = WindTalker

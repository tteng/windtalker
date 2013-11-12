fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'

class WindTalker

  constructor: (@channel, @host="121.199.14.113", @port=7781) ->
    @delimiter_ary = ['a8', 'b9', 'c0', 'd1']
    @greeting  = "m=#{@channel};u=dellsha01;p=jason3802;EX_HEAD=a8b9c0d1;EX_SIZE=1;"
    @client    = new net.Socket()
    @delta     = new Buffer 0
    [@data_size, @compressed_data_size] = [0, 0]
    [@head, @found_head] = [0, false]
    console.log "The cpu endian is #{os.endianness()}" 

  listen: ->
    @client.connect @port, @host, =>
      console.log "Connect to #{@host}:#{@port}"
      @client.write @greeting

    @client.on 'data', (data) =>
      console.log "\n\n==============================" 
      console.log "receive chunk size: #{data.length}"
      @delta = Buffer.concat [@delta, data]
      console.log "delta length: #{@delta.length}"
      
      unless @found_head
        unless @delta.length < 16
          for bite, i in @delta 
            console.log @delta[i].toString('16')
            if @isHead(data, i)
              @head = i 
              @found_head = true
              break

        if @found_head 
          @data_size = @delta.readUInt32LE(@head+4)
          @compressed_data_size = @delta.readUInt32LE(@head+4+4)
          console.log "bingooo, got the head:#{@head}."
          console.log "data_size: #{@data_size}"
          console.log "compressed_data_size: #{@compressed_data_size}"

      if @delta.length >= (@head + 4 + 4 + @data_size)
        @processStream @delta 
        @client.destroy()
      else
        console.log "continue receiving ..."

    @client.on 'close', ->
      console.log "Connection closed."

  processStream: (data) ->  
    console.log "God bless, received complete data"
    compressed_data = new Buffer @data_size
    compressed_data.fill 0
    @delta.copy compressed_data, 0, @head+4+4+4, @head+4++4+4+155
    zlib.inflate compressed_data, (error, result) ->
      throw error if error
      console.log "uncompressed data size: #{result.length}"
    #@delta = @delta.slice @tail+4+@data_size, @delta.length
    #restore data_size, compressed_data_size, head and found_head
    [@data_size, @compressed_data_size] = [0, 0]
    [@head, @found_head] = [0, false]

  
  isHead: (buff, idx) ->
    result = false
    bite = buff[idx]
   
    #### have no idea why this fail ####
    #if bite.toString('16').toLowerCase() is @delimiter_ary[3]
    #  if buff[idx+1] and buff[idx+1].toString('16').toLowerCase() is @delimiter_ary[2]
    #    if buff[idx+2] and buff[idx+2].toString('16').toLowerCase() is @delimiter_ary[1]
    #      if buff[idx+3] and buff[idx+3].toString('16').toLowerCase() is @delimiter_ary[0]
    #        result = true
    #result

    if bite and bite.toString('16').toLowerCase() is 'd1'
      if buff[idx+1] and buff[idx+1].toString('16').toLowerCase() is 'c0'
        if buff[idx+2] and buff[idx+2].toString('16').toLowerCase() is 'b9'
          if buff[idx+3] and buff[idx+3].toString('16').toLowerCase() is 'a8'
            result = true
    result

w = new WindTalker('IX')
w.listen()

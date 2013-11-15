fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'

class WindTalker

  constructor: (@channel, @host="121.199.14.113", @port=7781) ->
    @greeting  = "m=#{@channel};u=dellsha01;p=jason3802;EX_HEAD=a8b9c0d1;EX_SIZE=1;"
    @client    = new net.Socket()
    @delta     = new Buffer 0
    [@message_size, @head, @found_head] = [0, 0, false]
    console.log "The cpu endian is #{os.endianness()}" 

  listen: ->
    @client.connect @port, @host, =>
      console.log "Connect to #{@host}:#{@port}"
      @client.write @greeting

    #
    #  --------------------------------------------------------------------------------------
    #  |0xA8B9C0D1| EX_SIZE | CHUNK_SIZE| RAW_SIZE |        BINARYDATA                      |
    #  -------------------------------------------------------------------------------------|
    #  |  4bytes  | 4bytes  |  4bytes   |  4bytes  |        BINARYDATA                      |
    #  -------------------------------------------------------------------------------------|
    #  |  4bytes  |MSG_SIZE |CHUNK_SIZE | RAW_SIZE |        BINARYDATA                      |
    #  --------------------------------------------|------------长度为CHUNKSIZE-4-----------|
    #                                              |----------解压后长度为RAWSIZE-----------|
    #                                              -----------------------------------------|
    #                       |-------------------------长度为MSG_SIZE------------------------|
    #                                                                                       |
    #  ↑                    ↑                                                              ↑
    #  head                 current_cursor                                                 end_point
 

    @client.on 'data', (data) =>
      @delta = Buffer.concat [@delta, data]
      unless @found_head
        unless @delta.length < 16
          for bite, i in @delta 
            #console.log @delta[i].toString('16')
            if @isHead(data, i)
              @head = i 
              @found_head = true
              break

        if @found_head 
          @message_size =  @delta.readUInt32LE(@head+4)
          chunk_size = @delta.readUInt32LE(@head+4+4)
          raw_data_size = @delta.readUInt32LE(@head+4+4+4)
          console.log "bingooo, got the head:#{@head}."
          console.log "message_size: #{@message_size}, chunk_size: #{chunk_size}, raw_data_size: #{raw_data_size}"

      if @found_head and @delta.length >= (@head + 4 + 4 + @message_size)
        current_cursor = @head + 4 + 4
        end_point = @head + 4 + 4 + @message_size-1
        console.log "end_point should be #{end_point}"
        @split_and_inflate current_cursor, end_point
        console.log "have received a complete message, delta length: #{@delta.length}"
        @client.destroy()
        #@delta = @delta.slice @head+@message_size, @delta.length
        #@found_head = false
        #console.log "after slice, delta length: #{@delta.length}, found_head: #{@found_head}"
      else
        console.log "continue receiving ..."

    @client.on 'close', ->
      console.log "Connection closed."

  #
  #  --------------------------------------------------------------------------------------
  #  |0xA8B9C0D1| EX_SIZE | CHUNK_SIZE| RAW_SIZE |        BINARYDATA                      |
  #  -------------------------------------------------------------------------------------|
  #  |  4bytes  | 4bytes  |  4bytes   |  4bytes  |        BINARYDATA                      |
  #  -------------------------------------------------------------------------------------|
  #  |  4bytes  |MSG_SIZE |CHUNK_SIZE | RAW_SIZE |        BINARYDATA                      |
  #                       |-------------------------长度为MSG_SIZE------------------------------------------|
  #  --------------------------------------------|------------长度为CHUNKSIZE-4-----------|
  #                                              |----------解压后长度为RAWSIZE-----------|
  #                                              -----------------------------------------|
  #  ↑                    ↑                       ↑                                      ↑                 ↑
  #  head                 current_cursor          chunk_start                            chunk_end         end_point
 

  split_and_inflate: (current_cursor, end_point) ->
    if current_cursor < end_point
      console.log "current_cursor: #{current_cursor}"
      chunk_size    = @delta.readUInt32LE current_cursor
      raw_data_size = @delta.readUInt32LE current_cursor+4
      console.log "----------- current cursor is #{current_cursor} ----------------"
      chunk_start   = current_cursor + 8
      chunk_end     = chunk_start + chunk_size-1
      console.log "chunk_size: #{chunk_size}"
      console.log "raw_data_size: #{raw_data_size}"
      compressed_data = new Buffer chunk_size
      compressed_data.fill 0
      @delta.copy compressed_data, 0, chunk_start, chunk_end
      zlib.inflate compressed_data, (error, result) =>
        throw error if error
        console.log "uncompressed data size: #{result.length}"
        console.log "current_cursor in callback: #{current_cursor}"
        current_cursor = chunk_end + 1-4
        console.log "next current cursor should be: #{current_cursor}"
        console.log "end_point in callback: #{end_point}"
        @split_and_inflate current_cursor, end_point

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

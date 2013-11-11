fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'
os   = require 'os'

class WindTalker

  constructor: (@channel, @host="121.199.14.113", @port=7781) ->
    @delimiter_ary = ['a8', 'b9', 'c0', 'd1']
    @greeting = "m=#{@channel};u=dellsha01;p=jason3802;EX_HEAD=#{@delimiter_ary.join ''};EX_TAIL=#{@delimiter_ary.reverse().join ''}"
    @client   = new net.Socket()
    console.log "The cpu endian is #{os.endianness()}" 

  listen: ->
    @client.connect @port, @host, =>
      console.log "Connect to #{@host}:#{@port}"
      @client.write @greeting

    @client.on 'data', (data) =>
      data_copy = new Buffer data.length
      data.copy data_copy, 0, 0, data.length-1
      head = 0
      for bite, i in data_copy
        if @isHead(data, i)
          console.log "bingooo, got the head!"
          head = i 
        #console.log "#{i} - #{bite}"
        console.log "#{i} - #{bite.toString('16')} \n"
      @client.destroy()

    @client.on 'close', ->
      console.log "Connection closed."

  isHead: (buff, idx) ->
    result = false
    bite = buff[idx]
    
    #if bite.toString('16').toLowerCase() is @delimiter_ary[3]
    #  if buff[idx+1] and buff[idx+1].toString('16').toLowerCase() is @delimiter_ary[2]
    #    if buff[idx+2] and buff[idx+2].toString('16').toLowerCase() is @delimiter_ary[1]
    #      if buff[idx+3] and buff[idx+3].toString('16').toLowerCase() is @delimiter_ary[0]
    #        result = true
    #result

    if bite.toString('16').toLowerCase() is 'd1'
      if buff[idx+1] and buff[idx+1].toString('16').toLowerCase() is 'c0'
        if buff[idx+2] and buff[idx+2].toString('16').toLowerCase() is 'b9'
          if buff[idx+3] and buff[idx+3].toString('16').toLowerCase() is 'a8'
            result = true
    result


  isTail: (buff, idx) ->
    result = false
    bite = buff[idx]
    if bite.toString('16').toLowerCase() is 'a8'
      if buff[idx+1].toString('16').toLowerCase() is 'b9'
        if buff[idx+2].toString('16').toLowerCase() is 'c0'
          if buff[idx+3].toString('16').toLowerCase() is 'd1'
            result = true
    result

  wind_decode: (data) ->
    console.log "copyed data length: #{data.length}" 
    zlib.inflate data, (error, result) =>
      console.log "result.size: #{result.length}"


w = new WindTalker('IX')
w.listen()

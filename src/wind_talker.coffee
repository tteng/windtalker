fs   = require 'fs'
zlib = require 'zlib'
net  = require 'net'

class WindTalker

  constructor: (@channel, @host="121.199.14.113", @port=7781) ->
    @greeting = "m=#{@channel};u=xxx;p=xxx"     
    @client   = new net.Socket()


  listen: ->
    @client.connect @port, @host, =>
      console.log "Connect to #{@host}:#{@port}"
      @client.write @greeting
    

    @client.on 'data', (data) =>
      console.log "data: #{data}"
      @client.destroy()

    @client.on 'close', ->
      console.log "Connection closed."


w = new WindTalker('IX')
w.listen()

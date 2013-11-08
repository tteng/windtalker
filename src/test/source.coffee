fs    = require 'fs'
os    = require 'os'
Iconv = require('iconv').Iconv;
bufferpack = require 'bufferpack'

#  VERY IMPORTANT, TO DISTINGUISH CPU ENDIAN INFO.
console.log "The CPU endian is #{os.endianness()}"

fs.open __dirname + "/../../data/wsSample.dat", 'r', (err,fd) ->
  buf = new Buffer(156)
  buf.fill 0
  fs.read fd, buf, 0, 156, 0, (err, bytesRead, buf) ->
    #for i in [0..155] 
    #  console.log buf[i].toString '16'
    console.log buf.toString('utf8')

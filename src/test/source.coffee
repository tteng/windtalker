fs    = require 'fs'
os    = require 'os'

console.log "The CPU endian is #{os.endianness()}"

fs.open "/tmp/a.txt", 'r', (err,fd) ->
  buf = new Buffer 30
  buf.fill 0
  fs.read buf, 0, 30, 0, (err, bytesRead, buffer) ->
    console.log buffer.toString 'ascii'

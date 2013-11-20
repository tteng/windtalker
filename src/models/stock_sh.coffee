WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockSH extends WindTalker

  running_schedule: ->
    console.log settings.channels.sh

exports.StockSH = StockSH

stock_sh = new StockSH 'SH', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "child got #{msg}"
  if msg is 'start'
    stock_sh.listen()
    console.log "child will start()"
  else if  msg is 'stop'
    stock_sh.stop()
    console.log "child will stop()"
  process.send "[CHILD] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log "[CHILD] process##{process.pid} quit."

process.stdout.on 'data', (msg) ->
  console.log "[CHILD] process##{process.pid} stdout: #{msg}"

process.stderr.on 'data', (msg) ->
  console.log "[CHILD] process##{process.pid} stderr: #{msg}"

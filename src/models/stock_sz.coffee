WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockSZ extends WindTalker

stock_sz = new StockSZ 'SZ', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD] RECEIVED #{msg}"
  if msg is 'start'
    stock_sz.listen()
  process.send "[CHILD] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_sz.stop()
  process.send "[CHILD] process##{process.pid} exit."

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD] process##{process.pid} terminated."
  process.exit 0

#not work
process.stdin.on 'data', (msg) ->
  console.log "[CHILD] process##{process.pid} stdout: #{msg}"

process.stderr.on 'data', (msg) ->
  console.log "[CHILD] process##{process.pid} stderr: #{msg}"

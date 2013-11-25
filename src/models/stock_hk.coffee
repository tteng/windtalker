WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockHK extends WindTalker

  redisKey: (ticker) ->
    if ticker
      key = "#{settings.redisNamespace}:HK:#{ticker}"
    else
      null

stock_hk = new StockHK 'HK', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD][StockHK] RECEIVED #{msg}"
  if msg is 'start'
    stock_hk.listen()
  process.send "[CHILD][StockHK] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_hk.stop()
  process.send "[CHILD][StockHK] process##{process.pid} exit."

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD][StockHK] process##{process.pid} terminated."
  process.exit 0

#not work
process.stdin.on 'data', (msg) ->
  console.log "[CHILD][StockHK] process##{process.pid} stdout: #{msg}"

process.stderr.on 'data', (msg) ->
  console.log "[CHILD][StockHK] process##{process.pid} stderr: #{msg}"

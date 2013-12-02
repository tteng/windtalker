WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockSZ extends WindTalker
  redisKey: (ticker) ->
    if ticker
      key = "#{settings.redisNamespace}:SZ:#{ticker}"
    else
      null

stock_sz = new StockSZ 'SZ', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD][SZ] RECEIVED #{msg}"
  if msg is 'start'
    stock_sz.listen()
  process.send "[CHILD][SZ] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_sz.stop()
  process.send "[CHILD][SZ] process##{process.pid} exit."

process.on 'error', (err) ->
  console.log '[CHILD][SZ] Internal Error #{err} Occured.'
  process.send err
  process.exit 1

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD][SZ] process##{process.pid} terminated."
  process.exit 0

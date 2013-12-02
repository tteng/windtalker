WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockSH extends WindTalker
  redisKey: (ticker) ->
    if ticker
      key = "#{settings.redisNamespace}:SH:#{ticker}"
    else
      null

stock_sh = new StockSH 'SH', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD][StockSH] RECEIVED #{msg}"
  if msg is 'start'
    stock_sh.listen()
  process.send "[CHILD][StockSH] process##{process.pid} copy #{msg}."

process.on 'error', (err) ->
  console.log '[CHILD][SH] Internal Error #{err} Occured.'
  process.send err
  process.exit 1

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_sh.stop()
  process.send "[CHILD][StockSH] process##{process.pid} exit."

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD][StockSH] process##{process.pid} terminated."
  process.exit 0

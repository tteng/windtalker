WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockHK extends WindTalker

  ticker_regexp: ->
    @regxp ||= /^hk0/i

  redisKey: (ticker) ->
    if ticker and @ticker_regexp().test ticker
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

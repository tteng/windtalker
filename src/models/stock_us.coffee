WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockUS extends WindTalker
  redisKey: (ticker) ->
    if ticker
      key = "#{settings.redisNamespace}:US:#{ticker}"
    else
      null

stock_us = new StockUS 'US', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD][US] RECEIVED #{msg}"
  if msg is 'start'
    stock_us.listen()
  process.send "[CHILD][US] process##{process.pid} copy #{msg}."

process.on 'error', (err) ->
  console.log '[CHILD][US] Internal Error #{err} Occured.'
  process.send err
  process.exit 1

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_us.stop()
  process.send "[CHILD][US] process##{process.pid} exit."

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD][US] process##{process.pid} terminated."
  process.exit 0

WindTalker = require './wind_talker'
settings   = require '../config/settings'
logger     = require '../config/logger'

class StockIX extends WindTalker

  keys_map: ->
    obj = {
      'IXCOZCA0'     :   'U-CO',
      'IXCOZSA0'     :   'U-BE',
      'IXCOZWA0'     :   'U-WH',
      'IXFXAUDUSD'   :   'AUDUSD',
      'IXFXEURGBP'   :   'EURGBP',
      'IXFXEURUSD'   :   'EURUDS',
      'IXFXGBPUSD'   :   'GBPUSD',
      'IXFXUSDBRL'   :   'USDBRL',
      'IXFXUSDCAD'   :   'USDCAD',
      'IXFXUSDCHF'   :   'USDCHF',
      'IXFXUSDCNY'   :   'USDCNY',
      'IXFXUSDINR'   :   'USDINR',
      'IXFXUSDJPY'   :   'USDJPY',
      'IXFXUSDKRW'   :   'USDKRW',
      'IXFXUSDMXN'   :   'USDMXN',
      'IXFXUSDRUB'   :   'USDRUB',
      'IXFXUSDSGD'   :   'USDSGD',
      'IXFXUSDTHB'   :   'USDTHB',
      'IXFXXAG'      :   'SLV',
      'IXFXXAP'      :   'PLT',
      'IXFXXAU'      :   'GLD',
      'IXNECLA0'     :   'OIL'
    }

  redisKey: (ticker) ->
    corresponding_key = @keys_map[ticker]
    corresponding_key = ticker if ticker in ['IXFXNZDUSD', 'IXFXUSDTRY', 'IXIXUDI']
    corresponding_key = ticker
    if corresponding_key 
      key = "#{settings.redisNamespace}:IX:#{corresponding_key}"
    else
      null

stock_ix = new StockIX 'IX', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD][StockIX] RECEIVED #{msg}"
  if msg is 'start'
    stock_ix.listen()
  process.send "[CHILD][StockIX] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_ix.stop()
  process.send "[CHILD][StockIX] process##{process.pid} exit."

process.on 'SIGTERM', ->
  console.log 'SIGTERM ....'
  process.send "[CHILD][StockIX] process##{process.pid} terminated."
  process.exit 0

#not work
process.stdin.on 'data', (msg) ->
  console.log "[CHILD][StockIX] process##{process.pid} stdout: #{msg}"

process.stderr.on 'data', (msg) ->
  console.log "[CHILD][StockIX] process##{process.pid} stderr: #{msg}"

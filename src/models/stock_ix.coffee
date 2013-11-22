WindTalker = require './wind_talker'
settings   = require '../config/settings'
logger     = require '../config/logger'
redis      = require('../db/redis_util').createClient()

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

  analyze_data: (cursor, raw_buf) =>
    if cursor >= raw_buf.length  
      console.log "process finished." 
      return
    console.log "analyzing..."
    data = new Buffer 156
    data.fill 0
    result = ''
    buf = raw_buf.copy data, 0, cursor, cursor+156

    time_t = data.readUInt32LE(0)         
    result += "#{time_t},"

    market = data.toString('ascii', 4, 15).replace "\u0000.*", ''
    console.log market
    result += "#{market},"

    contract = data.toString 'ascii', 16, 31 
    result += "#{contract},"

    total_deal = data.readFloatLE(32)
    result += "#{total_deal},"

    latest_deal = data.readFloatLE(36)  
    result += "#{latest_deal},"

    holding = data.readFloatLE(40)
    result += "#{holding},"

    feature_price = data.readFloatLE(44)
    result += "#{feature_price},"

    m_fLastClose = data.readFloatLE(48)
    result += "#{m_fLastClose},"

    m_fOpen = data.readFloatLE(52)
    result += "#{m_fOpen},"

    m_fHigh = data.readFloatLE(56)
    result += "#{m_fHigh},"

    m_fLow = data.readFloatLE(60)
    result += "#{m_fLow},"

    m_fNewPrice = data.readFloatLE(64) 
    result += "#{m_fNewPrice},"

    m_fVolume = data.readFloatLE(68) 
    result += "#{m_fVolume},"

    m_fAmount = data.readFloatLE(72) 
    result += "#{m_fAmount},["

    i = 0
    buyBids = []                                #申买价
    while i < 5
      val = data.readFloatLE(76+i*4) 
      buyBids.push val
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    buyAmount = []
    while i < 5
      val = data.readFloatLE(96+i*4) 
      buyAmount.push val
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    sellBids = []
    while i < 5
      val = data.readFloatLE(116+i*4) 
      sellBids.push val
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    sellAmount = []
    while i < 5
      val = data.readFloatLE(136+i*4) 
      sellAmount.push val
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "]"

    @saveToDb time_t, market, m_fLastClose, m_fOpen, m_fHigh, m_fLow, m_fNewPrice, m_fVolume, m_fAmount

    #console.log "result: #{result}"
    result = null

    raw_buf = raw_buf.slice cursor+156, raw_buf.length
    cursor = 0
    @analyze_data cursor, raw_buf


  saveToDb: (time, ticker, fLastClose, fOpen, fHigh, fLow, fNewPrice, fVolume, fAmount) ->
    console.log "saving to db ..."
    console.log "#{time}, #{ticker}, #{fLastClose}, #{fOpen}, #{fHigh}, #{fLow}, #{fNewPrice}, #{fVolume}, #{fAmount}"
    #corresponding_key = @keys_map[ticker]
    #corresponding_key = ticker if ticker in ['IXFXNZDUSD', 'IXFXUSDTRY', 'IXIXUDI']
    corresponding_key = ticker
    if corresponding_key
      key = "#{settings.redisNamespace}:IX:#{corresponding_key}"
      key = corresponding_key
      console.log key
      redis.HMSET(key, "t", time, 
                       "close",   fLastClose, 
                       "open",    fOpen, 
                       "high",    fHigh, 
                       "low",     fLow, 
                       "current", fNewPrice, 
                       "volume",  fVolume, 
                       "amount",  fAmount
                       , (err, result) ->
                            console.log "[IX] [#{key}] #{result}"
                            console.error "[IX] update #{corresponding_key} failed for #{err}." if err
                 )

      #redis.hmset(key, {
      #                  "t":       "#{time}", 
      #                  "close":   "#{fLastClose}", 
      #                  "open":    "#{fOpen}", 
      #                  "high":    "#{fHigh}", 
      #                  "low":     "#{fLow}", 
      #                  "current": "#{fNewPrice}", 
      #                  "volume":  "#{fVolume}", 
      #                  "amount":  "#{fAmount}"
      #                 }, (err, result) ->
      #                      console.log "[IX] [#{key}] #{result}"
      #                      console.error "[IX] update #{corresponding_key} failed for #{err}." if err
      #           )

stock_ix = new StockIX 'IX', settings.host, settings.port

process.on 'message', (msg) ->
  console.log "[CHILD] RECEIVED #{msg}"
  if msg is 'start'
    stock_ix.listen()
  process.send "[CHILD] process##{process.pid} copy #{msg}."

process.on 'exit', ->
  console.log 'EXIT ....'
  stock_ix.stop()
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

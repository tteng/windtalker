WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockHK extends WindTalker

  running_schedule: ->
    console.log settings.channels.hk


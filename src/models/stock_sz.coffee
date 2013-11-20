WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockSZ extends WindTalker

  running_schedule: ->
    console.log settings.channels.sz


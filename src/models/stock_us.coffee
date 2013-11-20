WindTalker = require './wind_talker'
settings   = require '../config/settings'

class StockUS extends WindTalker

  running_schedule: ->
    console.log settings.channels.us


settings = require '../config/settings'
schedule = require 'node-schedule'

class Dispatcher

  constructor: ->
    @jobs = {}
    
  startJob: (job)->
    stock_job = require('child_process').fork(__dirname+"/stock_#{job}.js")
    @jobs[job] = stock_job
    @assignSchedule job
    stock_job.on 'message', (msg) ->
      console.log "[PARENT][RECEIVE] #{msg}"

  restartJob: (job) ->
    @stopJob job
    setTimeout (-> @startJob job), 3000

  stopJob: (job) ->
    @jobs[job].kill 'SIGTERM' if @jobs[job]

  startAll: ->
    for key, job of @jobs
      @startJob key

  stopAll: ->
    for key, job of @jobs
      @stopJob key

  assignSchedule: (job) ->
    if @jobs[job]
      func = "#{job}Schedule"
      eval "this.#{func}()"
      #global[func].call()
      invokFun = "#{job}JobCouldBeInvoked"
      #@jobs[job].send 'start' if global[invokFun].call()
      @jobs[job].send 'start' if eval "this.#{invokFun}()"

  ixSchedule: ->
    ruleStart = new schedule.RecurrenceRule()
    ruleStart.dayOfWeek = [1]
    ruleStart.hour = 6
    ruleStart.minute = 0
    schedule.scheduleJob ruleStart, ->
      @startJob 'ix'

    ruleStop = new schedule.RecurrenceRule()
    ruleStop.dayOfWeek = [6]
    ruleStart.hour = 5
    ruleStart.minute = 0
    schedule.scheduleJob ruleStop, ->
      @stopJob 'ix'

  ixJobCouldBeInvoked: ->
    date = new Date()     
    dayIdx = date.getDay()
    return false if dayIdx in [0]    
    return true if dayIdx in [2,3,4,5] 
    hour = date.getHours()
    return true if dayIdx == 1 and hour >= 6
    return true if dayIdx == 6 and hour <= 4
    return false

exports.Dispatcher = Dispatcher

dsp = new Dispatcher()

dsp.startJob 'ix'

setTimeout (-> dsp.stopAll()), 10000

process.on 'exit', ->
  console.log '[PARENT] going to exit.' 
  dsp.stopAll()

process.on 'SIGTERM', ->
  console.log '[PARENT] got SIGTERM ....'
  process.exit 0

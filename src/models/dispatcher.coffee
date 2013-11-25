settings = require '../config/settings'
logger   = require '../config/logger'
schedule = require 'node-schedule'

class Dispatcher

  constructor: ->
    logger.warn "welcome ..."
    @jobs = {}
    
  startJob: (job) ->
    @assignSchedule job

  invokeJob: (job) ->
    stock_job = require('child_process').fork(__dirname+"/stock_#{job}.js")
    @jobs[job] = stock_job
    stock_job.on 'message', (msg) ->
      console.log "[PARENT][RECEIVE] #{msg}"
    stock_job.send 'start'

  restartJob: (job) ->
    @stopJob job
    setTimeout (-> @startJob job), 3000

  stopJob: (job) ->
    @jobs[job].kill 'SIGTERM' if @jobs[job]
    delete @jobs[job]

  startAll: ->
    for key, any of settings.channels
      @startJob key

  stopAll: ->
    for key, job of @jobs
      @stopJob key

  assignSchedule: (job) ->
    console.log "going to assign schedule for #{job}"
    @["#{job}Schedule"].call()
    @invokeJob job if @["#{job}JobCouldBeInvoked"].call()

  ixSchedule: ->
    ruleStart = new schedule.RecurrenceRule()
    ruleStart.dayOfWeek = [1]
    ruleStart.hour = 6
    ruleStart.minute = 0
    schedule.scheduleJob ruleStart, =>
      @invokeJob 'ix'

    ruleStop = new schedule.RecurrenceRule()
    ruleStop.dayOfWeek = [6]
    ruleStart.hour = 5
    ruleStart.minute = 0
    schedule.scheduleJob ruleStop, =>
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

  shSchedule: ->
    ruleMorStart = new schedule.RecurrenceRule()
    ruleMorStart.dayOfWeek = [1,2,3,4,5]
    ruleMorStart.hour = 9
    ruleMorStart.minute = 15
    schedule.scheduleJob ruleMorStart, =>
      @invokeJob 'sh'

    ruleMorStop = new schedule.RecurrenceRule()
    ruleMorStop.dayOfWeek = [1,2,3,4,5]
    ruleMorStop.hour = 11
    ruleMorStop.minute = 30
    schedule.scheduleJob ruleMorStop, =>
      @stopJob 'sh'

    ruleAftStart = new schedule.RecurrenceRule()
    ruleAftStart.dayOfWeek = [1,2,3,4,5]
    ruleAftStart.hour = 13
    ruleAftStart.minute = 0
    schedule.scheduleJob ruleAftStart, =>
      @invokeJob 'sh'

    ruleAftStop = new schedule.RecurrenceRule()
    ruleAftStop.dayOfWeek = [1,2,3,4,5]
    ruleAftStop.hour = 15
    ruleAftStop.minute = 0
    schedule.scheduleJob ruleAftStop, =>
      @stopJob 'sh'

  shJobCouldBeInvoked: ->
    date = new Date()     
    dayIdx = date.getDay()
    return false if dayIdx in [0,6]    
    hour = date.getHours()
    minutes = date.getMinutes()
    return true if hour > 9 and hour < 11 
    return true if hour is 9 and minutes >= 15
    return true if hour is 11 and minutes < 30
    return true if hour >= 13 and hour < 15
    return false

  szSchedule: ->
    ruleMorStart = new schedule.RecurrenceRule()
    ruleMorStart.dayOfWeek = [1,2,3,4,5]
    ruleMorStart.hour = 9
    ruleMorStart.minute = 15
    schedule.scheduleJob ruleMorStart, =>
      @invokeJob 'sz'

    ruleMorStop = new schedule.RecurrenceRule()
    ruleMorStop.dayOfWeek = [1,2,3,4,5]
    ruleMorStop.hour = 11
    ruleMorStop.minute = 30
    schedule.scheduleJob ruleMorStop, =>
      @stopJob 'sz'

    ruleAftStart = new schedule.RecurrenceRule()
    ruleAftStart.dayOfWeek = [1,2,3,4,5]
    ruleAftStart.hour = 13
    ruleAftStart.minute = 0
    schedule.scheduleJob ruleAftStart, =>
      @invokeJob 'sz'

    ruleAftStop = new schedule.RecurrenceRule()
    ruleAftStop.dayOfWeek = [1,2,3,4,5]
    ruleAftStop.hour = 15
    ruleAftStop.minute = 0
    schedule.scheduleJob ruleAftStop, =>
      @stopJob 'sz'

  szJobCouldBeInvoked: ->
    date = new Date()     
    dayIdx = date.getDay()
    return false if dayIdx in [0,6]    
    hour = date.getHours()
    minutes = date.getMinutes()
    return true if hour > 9 and hour < 11 
    return true if hour is 9 and minutes >= 15
    return true if hour is 11 and minutes < 30
    return true if hour >= 13 and hour < 15
    return false

  hkSchedule: ->
    ruleMorStart = new schedule.RecurrenceRule()
    ruleMorStart.dayOfWeek = [1,2,3,4,5]
    ruleMorStart.hour = 9
    ruleMorStart.minute = 30
    schedule.scheduleJob ruleMorStart, =>
      @invokeJob 'hk'

    ruleMorStop = new schedule.RecurrenceRule()
    ruleMorStop.dayOfWeek = [1,2,3,4,5]
    ruleMorStop.hour = 12
    ruleMorStop.minute = 0
    schedule.scheduleJob ruleMorStop, =>
      @stopJob 'hk'

    ruleAftStart = new schedule.RecurrenceRule()
    ruleAftStart.dayOfWeek = [1,2,3,4,5]
    ruleAftStart.hour = 13
    ruleAftStart.minute = 0
    schedule.scheduleJob ruleAftStart, =>
      @invokeJob 'hk'

    ruleAftStop = new schedule.RecurrenceRule()
    ruleAftStop.dayOfWeek = [1,2,3,4,5]
    ruleAftStop.hour = 16
    ruleAftStop.minute = 0
    schedule.scheduleJob ruleAftStop, =>
      @stopJob 'hk'

  hkJobCouldBeInvoked: ->
    date = new Date()     
    dayIdx = date.getDay()
    return false if dayIdx in [0,6]    
    hour = date.getHours()
    minutes = date.getMinutes()
    return true if hour >= 10 and hour < 12
    return true if hour is 9 and minutes >= 30
    return true if hour >= 13 and hour < 16
    return false

  usSchedule: ->
    ruleMorStart = new schedule.RecurrenceRule()
    ruleMorStart.dayOfWeek = [1,2,3,4,5]
    ruleMorStart.hour = 22
    ruleMorStart.minute = 30
    schedule.scheduleJob ruleMorStart, =>
      @invokeJob 'us'

    ruleMorStop = new schedule.RecurrenceRule()
    ruleMorStop.dayOfWeek = [2,3,4,5,6]
    ruleMorStop.hour = 5 
    ruleMorStop.minute = 0
    schedule.scheduleJob ruleMorStop, =>
      @stopJob 'us'

  usJobCouldBeInvoked: ->
    date    = new Date()     
    dayIdx  = date.getDay()
    hour    = date.getHours()
    minutes = date.getMinutes()
    return true if dayIdx in [1,2,3,4,5] and hour >= 22 and minutes >= 30
    return true if dayIdx in [2,3,4,5,6] and hour < 5 
    return false

exports.Dispatcher = Dispatcher

dsp = new Dispatcher()

dsp.startJob 'sz'

process.on 'exit', ->
  console.log '[PARENT] going to exit.' 
  dsp.stopAll()

process.on 'SIGTERM', ->
  console.log '[PARENT] got SIGTERM ....'
  process.exit 0

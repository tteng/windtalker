## Module dependencies
fs = require "fs"
env = require "./settings"

# Debugging levels
ERROR = 3
WARN = 2
INFO = 1
LOG = 0

# Empty function
NOOP_FN = ->

# A list of debugging levels
LEVELS = ["log", "info", "warn", "error"]

PID = "[#{process.pid}]"

NAME_TAG =
  "log": "LOG -"
  "info": "\u001b[32mINFO\u001b[0m -"
  "warn": "\u001b[33mWARNING\u001b[0m -"
  "error": "\u001b[31mERROR\u001b[0m -"

# 更新日志位置的时间间隔（4小时）
ROTATION_INTERVAL = 4 * 60 * 60 * 1000
# 刷新日志的间隔（5秒钟）
FLUSH_INTERVAL = 5 * 1000

# Local reference of Array join() method
join = Array.prototype.join

# A `Logger` supports basic debugging level controlling
#
# Usage:
#
#   logger = require("./util/logger")
#   logger.setLevel(logger.ERROR)
#   logger.error "msg"
class Logger

  constructor: ->
    @_level = LOG
    @_path = null
    @_resetInterval = null
    @_flushInterval = null
    @setLevel(@_level)
    @setPath(@_path)
    @_async()

  # Set log path
  setPath: (path) ->
    if path
      console.info "[logger:setPath] Set logger path to: #{path}"
      @_path = path
      @_resetStream()
      unless @_resetInterval
        @_resetInterval = setInterval (=> @_resetStream()), ROTATION_INTERVAL
      @_flushLog = @_flushLogToFile
    else
      console.info "[logger:setPath] Use console for logger"
      @_flushLog = @_flushLogToConsole
    this

  # Set debugging level
  setLevel: (level=0) ->
    console.info "[logger:setPath] Set logger level to #{level}"
    for method, i in LEVELS
      if i < level then @_defineNoopMethod(method) else @_defineMethod(method)
    @_level = level
    this

  log: NOOP_FN
  info: NOOP_FN
  warn: NOOP_FN
  error: NOOP_FN

  _defineMethod: (name) ->
    tag = NAME_TAG[name]
    if env.DEBUG
      # 如果是在调试环境下，实时输出日志
      @[name] = ->
        #console.trace()
        console[name](PID, (new Date).toISOString(), tag, join.call(arguments))
    else
      # 如果在生产环境下，异步输出日志
      @[name] = =>
        @_cache[name].push "#{PID} #{new Date().toISOString()} #{tag} #{join.call(arguments)}\r\n"
        return

  _defineNoopMethod: (name) ->
    @[name] = NOOP_FN

  # 执行一个异步的加载日志的过程
  _async: ->
    @_cache =
      log: []
      info: []
      warn: []
      error: []
    @_flushInterval = setInterval =>
      for key, value of @_cache
        continue if value.length == 0
        logs = value.join("")
        if @_flushLog(key, logs)
          value.length = 0
    , 5 * 1000

  # 把日志写入文件
  _flushLogToFile: (level, logs) ->
    # 如果写入的文件不可用的话，输出日志到 Console
    unless @_stream and @_stream.writable
      @_flushLogToConsole(level, logs)
      return true
    @_stream.write logs
    return true

  # 把日志输出到 Console
  _flushLogToConsole: (level, logs) ->
    console[level](logs)
    return true

  # 重置文件句柄
  _resetStream: ->
    return unless @_path
    today = new Date()
    year = "#{today.getFullYear()}"
    month = "#{today.getMonth() + 1}"
    month = "0#{month}" unless month[1]
    day = "#{today.getDate()}"
    day = "0#{day}" unless day[1]
    logPath = @_path
      .replace("%Y", year)
      .replace("%m", month)
      .replace("%d", day)
      # .replace("%t", today.toLocaleTimeString())
    # 仅当日志路径发生变化时才重置日志文件
    return if logPath == @_realPath
    @_realPath = logPath
    options =
      flags: 'a'
      encoding: 'utf-8'
      mode: '0644'
    # 关闭之前的 Stream
    if @_stream
      try
        @_stream.destroySoon()
      catch error
        @error "[logger:_resetStream] Failed to close stream. Error: #{error}"
    try
      @_stream = fs.createWriteStream logPath, options
      logger.info "[logger:_resetStream] Rotate to new log path: #{logPath}"
    catch error
      @error "[logger:_resetStream] Failed to create stream. Error: #{error}"
      @_stream = null
    return

# Default logger for all modules
logger = new Logger()
logger.ERROR = ERROR
logger.WARN = WARN
logger.INFO = INFO
logger.LOG = LOG

module.exports = logger

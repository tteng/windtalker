Settings = 
  host:     '121.199.14.113',
  port:     7781,
  username: process.env.WTALKER_UNAME,
  password: process.env.WTALKER_PWD,
  channels:
    ix: ['1-6',       '06:00-05:00'],
    sh: ['1,2,3,4,5', '09:15-11:30, 13:00-15:00'],
    sz: ['1,2,3,4,5', '09:15-11:30, 13:00-15:00'],
    hk: ['1,2,3,4,5', '09:30-12:00, 13:00-16:00'],
    us: ['1,2,3,4,5,6', '22:30-05:00']
    #mt: ['1-6',       '06:00-05:00']

  redisHost: "127.0.0.1",

  redisPort: 6379,

  redisNamespace: "thsocket"

  debug: false

module.exports = Settings

redis      = require('../db/redis_util').createClient()

redis.hmset "xiaosan", "name", "yangpengyuan", "age", 25, "gender", "male", (error, result) ->
  console.log "error: #{error}"
  console.log result

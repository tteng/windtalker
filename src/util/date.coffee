#Date utility

Date.prototype.yyyymmdd = ->
  yyyy = this.getFullYear().toString()                                    
  mm   = (this.getMonth()+1).toString() # getMonth() is zero-based         
  dd   = this.getDate().toString()             
  "#{yyyy}-#{mm}-#{dd}"

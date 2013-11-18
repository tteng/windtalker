fs    = require 'fs'
os    = require 'os'
zlib  = require 'zlib'
Iconv = require('iconv').Iconv

#  VERY IMPORTANT, TO DISTINGUISH CPU ENDIAN INFO.
console.log "The CPU endian is #{os.endianness()}"

#  一段二进制文件可能包含一段或者多段buffer，基于tcp传输的原理(MTU大小)，最后一段buffer有可能是完整数据也有可能是非完整数据
#  处理过程:
#  1、wsSample.wsz 为 多个 zlib 数据块 的合集；
#    wsSample.dat 为 解包之后的 dat文件（每条记录156字节）
#    wsSample.txt、wsSample.csv： 将 wsSample.dat 转化为 txt 格式后的数据。
#  
#  2、对于wsSample.wsz，具体说明如下：
#  
#    2.1  首先读出前面4字节（0x000011C5，即十进制的4549），4549-4=4545，这个4545是第一块zlib压缩块长度（4549为第一块压缩块长度加上原始长度4字节，每个压缩块均是这样的）；
#    2.2  然后读出次4字节（0x000049BC，即十进制的18876），这是第一块zlib压缩包解压缩之后的原始数据长度；
#    2.3  然后再读入4545字节，就是第一块压缩包的长度，将这4545字节使用zlib解压缩（注意，这4545字节才是zlib压缩包）。
#    2.4  以上步骤，就完成了第一块压缩包的解压缩。下面进行第二块压缩包的解压缩。
#  
#    2.5  再读出4字节（0x0000131E，即十进制的4894）4894-4=4890，这是第二块zlib压缩包长度；
#    2.6  读出次4字节（0x00003E28，即十进制的15912），这是第二块zlib压缩包解压缩之后的原始数据长度；
#    2.7  然后再读入4890字节，就是第二块压缩包的长度，将这4890字节使用zlib解压缩（注意，这4890字节才是zlib压缩包）。
#    2.8  以上步骤，就完成了第二块压缩包的解压缩。下面进行第三块压缩包的解压缩。
#  
#    2.9  再读出4字节（0x00000AFA，即十进制的2810），2810-4=2806，这是第三块zlib压缩包长度；
#    2.10 读出次4字节（0x00002970，即十进制的10608），这是第三块zlib压缩包解压缩之后的原始数据长度；
#    2.11 然后再读入2806字节，就是第三块压缩包的长度，将这2806字节使用zlib解压缩（注意，这2806字节才是zlib压缩包）。
#    2.12 此时，整个文件已处理完毕了。说明该文件中只有三个压缩块。
#    2.13如果文件尚未处理完毕，则继续处理下一块压缩块，直到全部压缩块处理完毕。

class A

  test: ->
    fs.open __dirname + "/../../data/wsSample.wsz", 'r', (err,fd) =>
      if err
        console.log "[Error] read origin data failed"
      else
        iterate_data_file = @iterate_data_file
        fs.stat __dirname + "/../../data/wsSample.wsz", (err, stat) =>
          if err
            console.log "[Error] get origin file size failed"
          else
            file_size = stat.size
            console.log "origin file size: #{file_size}"
            @iterate_data_file fd, 0, file_size

  iterate_data_file: (fd, cursor, file_size) ->
    if cursor >= file_size
      console.log "reach file end, that's all."
      return
    meta_buf = new Buffer 8
    meta_buf.fill 0
    fs.read fd, meta_buf, offset=0, length=8, position=cursor, (err, bytesRead, buffer) =>
      chunk_size = meta_buf.readUInt32LE 0
      raw_data_size = meta_buf.readUInt32LE 4
      data_buf = new Buffer chunk_size
      data_buf.fill 0
      console.log "cursor: #{cursor}, chunk_size: #{chunk_size-4}, raw_data_size: #{raw_data_size}, copy index from #{cursor+4+4} to #{cursor+4+4+chunk_size-4-1}"
      iterate_buf = @iterate_buf
      fs.read fd, data_buf, 0, chunk_size-4, cursor+4+4, (err, bytesRead, buffer) =>
        @iterate_buf data_buf, raw_data_size
      cursor = cursor+4+4+chunk_size-4
      @iterate_data_file fd, cursor, file_size

  iterate_buf: (raw_buf, raw_data_size) ->
    console.log "raw buf size: #{raw_buf.length}"
    zlib.inflate raw_buf, (error, result) => 
      if error
        console.log "[Error] inflate data failed."
        throw error
      else
        if result.length is raw_data_size
          console.log "[Info] inflate succeed."
          if result.length % 156 is 0
            @analyze_data 0, result
          else
            consloe.log "[Error] invalid buffer size" 
     
  analyze_data: (cursor, raw_buf) =>
    if cursor >= raw_buf.length  
      console.log "process finished." 
      return
    console.log "analyzing..."
    data = new Buffer 156
    data.fill 0
    result = ''
    buf = raw_buf.copy data, 0, cursor, cursor+156-1

    time_t = data.readUInt32LE(0)         
    console.log "time_t: #{time_t}"
    result += "#{time_t},"

    market = data.toString 'ascii', 4, 15
    console.log "mar: #{market}"
    result += "#{market},"

    contract = data.toString 'ascii', 16, 31 
    console.log "contract: #{contract}"
    result += "#{contract},"

    total_deal = data.readFloatLE(32)
    console.log "total_deal: #{total_deal}"
    result += "#{total_deal},"

    latest_deal = data.readFloatLE(36)  
    console.log "latest_deal: #{latest_deal}"
    result += "#{latest_deal},"

    holding = data.readFloatLE(40)
    console.log "holding: #{holding}"
    result += "#{holding},"

    feature_price = data.readFloatLE(44)
    console.log "feature_price: #{feature_price}"
    result += "#{feature_price},"

    m_fLastClose = data.readFloatLE(48)
    console.log "m_fLastClose: #{m_fLastClose}"
    result += "#{m_fLastClose},"

    m_fOpen = data.readFloatLE(52)
    console.log "m_fOpen: #{m_fOpen}"
    result += "#{m_fOpen},"

    m_fHigh = data.readFloatLE(56)
    console.log "m_fHigh: #{m_fHigh}"
    result += "#{m_fHigh},"

    m_fLow = data.readFloatLE(60)
    console.log "m_fLow: #{m_fLow}"
    result += "#{m_fLow},"

    m_fNewPrice = data.readFloatLE(64) 
    console.log "m_fNewPrice: #{m_fNewPrice}"
    result += "#{m_fNewPrice},"

    m_fVolume = data.readFloatLE(68) 
    console.log "m_fNewPrice: #{m_fVolume}"
    result += "#{m_fVolume},"

    m_fAmount = data.readFloatLE(72) 
    console.log "m_fAmount: #{m_fAmount}"
    result += "#{m_fAmount},["

    i = 0
    while i < 5
      val = data.readFloatLE(76+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(96+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(116+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "],["

    i = 0
    while i < 5
      val = data.readFloatLE(136+i*4) 
      result += "#{val}"
      result += "," unless i == 4
      i+=1
    result += "]"

    console.log "result: #{result}"
    result = null

    raw_buf = raw_buf.slice cursor+156, raw_buf.length
    cursor = 0
    @analyze_data cursor, raw_buf

a = new A()
a.test()

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

buf_length          = 0
reserved_bytes_len  = 4
raw_buf_length      = 0

fs.open __dirname + "/../../data/wsSample.wsz", 'r', (err,fd) ->
  #wsSample.wsz 的第一个四个字节为数据长度, 第二个四个字节为zlib解压缩后数据长度
  buf = new Buffer(4)
  buf.fill 0
  fs.read fd, buf, 0, reserved_bytes_len, 0, (err, bytesRead, buf) ->
    buf_length = buf.readUInt32LE(0)
    fs.read fd, buf, 0, reserved_bytes_len, 0+4, (err, bytesRead, buf) ->
      raw_buf_length = buf.readUInt32LE(0)
      console.log "buff length: #{buf_length}"
      console.log "raw buff length: #{raw_buf_length}"
      encrypt_data = new Buffer raw_buf_length
      fs.read fd, encrypt_data, 0, raw_buf_length, 0+4+4, (err, bytesRead, buf) ->
        zlib.inflate encrypt_data, (error, result) ->
          #console.log "result.size: #{result.length}"
          #conv = new Iconv 'GB2312', 'UTF-8//TRANSLIT//IGNORE'
          #data = (conv.convert(result)).toString 'utf8'  
          #console.log data
          #console.log result.toString('utf-8', 0, 155)
          console.log result.toString 'utf-8', 0, result

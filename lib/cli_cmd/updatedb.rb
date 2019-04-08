#!/usr/bin/env ruby
#
# pwcrack updatedb
# Author L
#

module CLI
  using Rainbow

  def self.updatedb(word_file)
    start = Time.now
    puts "[*] Start creating the local DB...".white
    puts

    hashes = {
      :md5   => {},
      :md5x2 => {},
      :md5x3 => {},
      :sha1  => {},
      :mysql => {},
    }

    md5 = OpenSSL::Digest::MD5.new
    sha1 = OpenSSL::Digest::SHA1.new
    words = open(word_file).each(chomp:true).to_a

    progressbar = ProgressBar.create(
      :title  => 'Progress',
      :format => ' %t: |%E |%b>%i|%j%%',
      :total  => 100,
      :length => 75,
    )
    n = words.size / 99

    words.each_with_index do |word, i|

      sha1b = sha1.digest(word)
      md5_1 = md5.digest(word)
      md5_2 = md5.digest(md5_1)
      md5_3 = md5.hexdigest(md5_2)
      md5_1_hex = md5_1.unpack1('H*')
      md5_2_hex = md5.hexdigest(md5_1_hex)
      md5_3_hex = md5.hexdigest(md5_2_hex)
      md5_1_hex_up = md5_1_hex.upcase
      md5_2_hex_up = md5.hexdigest(md5_1_hex_up).upcase
      md5_3_hex_up = md5.hexdigest(md5_2_hex_up)

      hashes.keys.each do |algo|
        case algo
        when :md5
          hashes[algo][ md5_1[4,8].bytes2int ] = i
          # md5(unicode)
          hashes[algo][ md5.hexdigest(word.encode('utf-16le'))[8,16].hex2int ] = i
        when :md5x2
          hashes[algo][ md5_2[4,8].bytes2int ] = i
          hashes[algo][ md5_2_hex[8,16].hex2int ] = i
          hashes[algo][ md5_2_hex_up[8,16].hex2int ] = i
        when :md5x3
          hashes[algo][ md5_3[8,16].hex2int ] = i
          hashes[algo][ md5_3_hex[8,16].hex2int ] = i
          hashes[algo][ md5_3_hex_up[8,16].hex2int ] = i
        when :sha1
          hashes[algo][ sha1b[5,8].bytes2int ] = i
        when :mysql
          mysql_hash = sha1.hexdigest(sha1b)
          hashes[algo][ mysql_hash[10,16].hex2int ] = i
        end
      end

      progressbar.increment if i % n == 1
    end
    progressbar.finish

    db_dir = "#{ROOT}/data/db"
    Dir.mkdir db_dir unless Dir.exist? db_dir

    dump_obj = lambda do |name, obj|
      filename = "#{db_dir}/#{name}.bin"
      begin
        File.binwrite(filename, MessagePack.pack(obj))
      rescue Errno::EACCES
        abort "[!] Save #{filename} Errno::EACCES"
      end
      msize = File.size(filename).to_f / 1024 / 1024
      algo = "#{name}".center 7

      puts "[+] %s db (%7s) : [%4.1fM] data/db/%s.bin" % [algo.bold, obj.size, msize, name]
      msize
    end

    puts
    puts '[*] Save Database...'
    hashes['words'] = words
    count = hashes.sum { |algo, obj|
      dump_obj.call(algo, obj)
    }
    msize = '%4.1fM'.bold % count
    puts "[*] Database total storage:  #{msize}"

    seconds = Time.now - start
    puts
    puts "[*] PWCrack creating local DB in #{'%.2f'.bold} seconds.".white % seconds
    exit
  end

end

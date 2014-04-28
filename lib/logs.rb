DEBUG_MODE = true 


def get_time
  Time.now.ctime[4..15]
end

### adds an outputter to your definitions.
#FileOutputter.new('logs_directory', {:filename=>("log/%8.8s.log" % get_time).gsub(/ /, '_')})


# method to log strings.
# log(:info, "%s", "str to interpolate")
# log(:info, "string")
# log(:debug, "string")
def log(sym, str)
  msg = "#{get_time.gsub(/ /, '_')}: #{str}"
  # dump the message to all loggers.
  puts "#{sym} #{msg}"

  if sym == :info && $dplayer_list
    $dplayer_list.each do |ch|
      if ch.level >= LEVEL_IMM
        ch.text_to_player msg +  ENDL
      end
    end
  end
end



# logs exceptions and backtrace.
def log_exception(e, sym=:error)
  ar = [e.message]  
  ar = ar + e.backtrace
  ar.each do |element|
    puts "#{sym} #{element}"
  end
  if sym == :info && $dplayer_list
    $dplayer_list.each do |ch|
      if ch.level >= LEVEL_IMM
        ar.each do |element|
          ch.text_to_player element + ENDL
        end
      end
    end
  end
end

if DEBUG_MODE == true
  log(:debug, "Debugging is turned on.  Debug logs are NOT saved. They only appear here. (In STDOUT.)")
end

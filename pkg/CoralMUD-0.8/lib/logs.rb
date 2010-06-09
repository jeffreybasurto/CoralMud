DEBUG_MODE = true 


def get_time
  Time.now.ctime[4..12]
end

### adds an outputter to your definitions.
FileOutputter.new('logs_directory', {:filename=>("log/%8.8s.log" % get_time).gsub(/ /, '_')})

Logger.new('LOG').level = INFO
Logger.new 'CONSOLE' 

Logger['LOG'].outputters = Outputter['logs_directory'] ### This is everything but debug messages.  This should go to logs and imm channel.
Logger['CONSOLE'].outputters = Outputter['stdout'] ### only output to standard output.  Definitely not logs_directory.


# method to log strings.
# log(:info, "%s", "str to interpolate")
# log(:info, "string")
# log(:debug, "string")
def log(sym, str)
  msg = "#{get_time.gsub(/ /, '_')}: #{str}"
  # dump the message to all loggers.
  Logger['CONSOLE'].send(sym, msg) 
  Logger['LOG'].send(sym, msg)
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
    Logger['LOG'].send(sym, element)
    Logger['CONSOLE'].send(sym, element)
  end
end

if DEBUG_MODE == true
  log(:debug, "Debugging is turned on.  Debug logs are NOT saved. They only appear here. (In STDOUT.)")
end

require 'log4r'
include Log4r

FileOutputter.new("roarrr", {:filename=>"testlogfile"})
StdoutOutputter.new 'console'

# create a logger named 'mylog' that logs to stdout
mylog = Logger.new 'mylog'
mylog.outputters << Outputter['console'] << Outputter['roarrr']


# Now we can log.
def do_log(log)
  log.debug "This is a message with level DEBUG"
  log.info "This is a message with level INFO"
  log.warn "This is a message with level WARN"
  log.error "This is a message with level ERROR"
  log.fatal "This is a message with level FATAL"
end
do_log(mylog)


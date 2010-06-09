require 'eventmachine'
module Rclient
  def post_init 
    $client = self
  end
  def receive_data data 
    print data 
  end
  def unbind 
    print "Connection closed." + "\r\n"
    EventMachine::stop_event_loop
  end
end

# Autonomous thread
receive_thread = Thread.new do
  loop do 
    next if (s = gets.strip).empty?
    $client.send_data s + "\r\n"
  end 
end

EventMachine::run { EventMachine::connect "mudbytes.net", 5000, Rclient }



require 'eventmachine'
load 'lib/CMI/packet.rb'
$cmiclient = nil
module Rclient
  def post_init
    $cmiclient = self
    send_data Packet.login("CoralMud")

  end
 
  def receive_data data
    # TODO need to make some way to capture and ensure a full packet is being sent.
    # Probably a delimiter but maybe just using the first 4 bytes for string length each time.
    packet = Packet.new(data)

    error = packet.is_invalid?
    # if there was an error then let's act upon it.
    if error
      error.execute
      return
    end

    # it's valid, so let's execute it.
    packet.execute
  end
 
  def unbind 
    log :info, "Connection to CMI-Server closed."
  end
end
 



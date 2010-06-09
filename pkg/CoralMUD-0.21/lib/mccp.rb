# MCCP is not used.
# This was the start of an attempt to implement MCCP before it was scrapped.
# If someone else has time to try to get it working then +1 :) 

def test_mccp string
  s = Zlib::Deflate.deflate(string, 9)
  log :debug, "#{s}"
  log :debug, "#{Zlib::Inflate.inflate(s)}"
  log :debug, "#{Zlib::Inflate.inflate("ROAR IN YOUR FACE.") rescue "ROAR IN YOUR FACE."}"
end

def mccp_initialize d
  d.text_to_socket START_MCCP
  d.mccp = Zlib::Deflate.new(9)
end


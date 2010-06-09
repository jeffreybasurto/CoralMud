
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


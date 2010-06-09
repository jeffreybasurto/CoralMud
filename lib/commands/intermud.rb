class Player
  def cmd_intermud tab, arg
    $cmiclient.send_data Packet.chat(arg, self.name).to_s
  end
end

class Player
  def cmd_sockets command_table_entry, arg
    width = 76
    buf =  "_".center(width, '_') + ENDL
    buf << "__sockets_connected__".ljust(width, '_') + ENDL
    $dsock_list.each do |dsock|
      xPlayer = dsock.player
      buf << "=" + (" %-12s #{dsock.state} #{dsock.addr}" % (xPlayer ? xPlayer.name : "")).ljust(width-2) + "=" + ENDL
    end
    buf << "=".center(width, '=') + ENDL
    text_to_player buf
  end
end


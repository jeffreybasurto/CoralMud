class Player
  def cmd_who command_table_entry, arg
    width = 76
    buf =  "_".center(width, '_') + ENDL
    buf << "__players_online__".ljust(width, '_') + ENDL
    $dsock_list.each do |dsock|
      next if dsock.state != :state_playing
      xPlayer = dsock.player
      next if xPlayer == nil
      buf << "=" + (" %-12s " % xPlayer.name).ljust(width-2) + "=" + ENDL
    end
    buf << "=".center(width, '=') + ENDL
    view buf
  end
end

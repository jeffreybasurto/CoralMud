class Player
  def cmd_linkdead command_table_entry, arg
    found = []
    $dplayer_list.each do |xPlayer|
      if xPlayer.socket.nil?
        found << xPlayer
      end
    end

    view "#{peek(found).sub("nothing", "Nobody")} #{found.count <= 1? "is" : "are"} currently linkdead." + ENDL
  end
end

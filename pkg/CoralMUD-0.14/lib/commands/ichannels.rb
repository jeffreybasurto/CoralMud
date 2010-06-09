class Player
  ### If no argument display all available channels.
  def cmd_ichannels command_table_entry, arg
    buf = "The following commands are available:" + ENDL
    i = 0
    $imc_channel_list.each_pair do |k,v|
      i += 1
      z = "[On]"
      buf << v[1] + ("[" + i.to_s + "] " + v[0]).ljust(25) + k.to_s.ljust(12) + z + ENDL
    end
    text_to_player buf
  end
end

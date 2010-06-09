class Player
  def cmd_shutdown command_table_entry, arg
    text_to_world ("The game is rebooting.  Please come back in a few minutes." + ENDL)
    $shut_down = true
  end
end

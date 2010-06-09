class Player
  def cmd_reboot command_table_entry, arg
    text_to_world ("The game is rebooting.  Please come back in a few minutes." + ENDL)
    $reboot = true
  end
end


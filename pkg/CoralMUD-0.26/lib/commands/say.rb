class Player
  def cmd_say command_table_entry, arg
    if arg == ''
      text_to_player "Say what?" + ENDL
      return
    end
    communicate self, arg, :comm_local
  end
end

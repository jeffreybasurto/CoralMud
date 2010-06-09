class Player
  def cmd_save command_table_entry, arg
    view "Player files are autosaved.  There is no need to save manually." + ENDL
    save_to_database
  end
end

class Player
  def cmd_help command_table_entry, arg
    if arg == nil
      length = 65
      col = 0
      buf = "__HELP_FILES__".ljust(length, '_') + ENDL
      $help_list.each do |pHelp|
        buf << " %-19.18s" % pHelp.keyword
        col += 1
        buf << ENDL if col % 4 == 0
      end
      buf << ENDL if col % 4 != 0
      buf << "Syntax:  help <topic>" + ENDL
      text_to_player buf
      return
    end

    found = Help.find(arg) # Search for arg in our help files.

    if !found
      text_to_player "No helpfile found." + ENDL
    else
      text_to_player "#{found.keyword}" + ENDL +
                     "#{found.text}" + ENDL
    end
  end

end

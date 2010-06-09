class Player
  def cmd_wizhelp command_table_entry, arg
    col = 0
    buf = "#RImmortal Commands" + ENDL
    $tabWizCmd.each do |c|
      next if c.hidden
      buf << " %-14.14s" % c.cmd_name
      col += 1
      buf << ENDL if col % 5 == 0
    end
    buf << "#n"
    buf << ENDL if col % 5 > 0
    view buf
  end
end

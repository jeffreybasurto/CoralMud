class Player
  def cmd_commands command_table_entry, arg
    f = FormatGenerator.new

    buf = "#uCommands#u" + ENDL 
    $tabCmd.sort {|a, b| a.cmd_name <=> b.cmd_name}.each do |c|
      buf << " %-14.14s" % c.cmd_name
      buf << f.resume
    end
    buf << f.end
    view buf
  end
end


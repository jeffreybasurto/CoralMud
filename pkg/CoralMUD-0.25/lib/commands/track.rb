class Player
  def cmd_track command_table_entry, r
    m = Automap.new(r.in_room, [(-5..5), (-2..2)])
    m.view(self)
  end
end

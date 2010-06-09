class Player
  def cmd_east command_table_entry, arg
    view "You walk east." + ENDL
    if in_room.exit_list[1] && in_room.exit_list[1].flags_state.is_set?(:closed)
      view "The exit is closed." + ENDL
      return
    end
    if !in_room.exit_list[1]
      if flags.include?("build walk")
        buildwalk(1)
      else
        view "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[1].enter(self)
  end
end

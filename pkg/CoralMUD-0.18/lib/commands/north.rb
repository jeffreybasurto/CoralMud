class Player
  def cmd_north command_table_entry, arg
    text_to_player "You walk north." + ENDL
    if in_room.exit_list[0] && in_room.exit_list[0].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end

    if !in_room.exit_list[0]
      if flags.include?("build walk")
        buildwalk(0)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[0].enter(self)
  end
end

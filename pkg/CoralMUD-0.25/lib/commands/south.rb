class Player
  def cmd_south command_table_entry, arg
    text_to_player "You walk south." + ENDL

    if in_room.exit_list[2] && in_room.exit_list[2].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end

    if !in_room.exit_list[2]
      if flags.include?("build walk")
        buildwalk(2)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[2].enter(self)
  end
end

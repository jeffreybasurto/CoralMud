class Player
  def cmd_west command_table_entry, arg
    text_to_player "You walk west." + ENDL

    if in_room.exit_list[3] && in_room.exit_list[3].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end
    if !in_room.exit_list[3]
      if flags.include?("build walk")
        buildwalk(3)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[3].enter(self)
  end
end

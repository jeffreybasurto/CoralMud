class Player
  def cmd_open cte, arg
    ex = in_room.exit_list[arg]

    if !ex || !ex.flags_state.is_set?(:has_door)
      text_to_player("There is no door that direction." + ENDL)
      return
    end

    if !ex.flags_state.is_set?(:closed)
      text_to_player("That door isn't closed." + ENDL)
      return
    end
    ex.open
    text_to_player("You open the door." + ENDL)
  end
end

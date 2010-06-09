class Player
  def cmd_close cte, arg
    ex = in_room.exit_list[arg]
    if !ex == nil || !ex.flags_state.is_set?(:has_door)
      text_to_player("There is no door that direction." + ENDL)
      return
    end

    if ex.flags_state.is_set?(:closed)
      text_to_player("That door is already closed." + ENDL)
      return
    end
    ex.close
    text_to_player("You close the door." + ENDL)
  end
end

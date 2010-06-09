
class Player
  def cmd_reset tab_entry, arg
    in_room.reset
    view "The room you are in was reset." + ENDL
  end
end

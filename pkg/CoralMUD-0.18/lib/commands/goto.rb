class Player
  def cmd_goto command_table_entry, arg
    case arg
    when Array
      found = arg
    when String
      found = Tag.find_any_obj arg
    end
    if found == nil
      view "That isn't a valid vtag or character name." + ENDL
      return
    end

    case found[0]
    when Player then found = found[0].in_room
    when Room then found = found[0]
    else found = nil
    end

    if found == nil
      view "That isn't a valid room or character." + ENDL
      return
    end

    room = found # must be of type Room

    if room == in_room
      view "You are already there." + ENDL
      return
    end

    if (in_room != nil)
      in_room.text_to_room "#{name} disappears in a cloud of sulfur." + ENDL
      in_room.remove_player(self)
    end
    room.accept_player(self)
    room.text_to_room "#{name} appears in a cloud of sulfur." + ENDL
  end
end

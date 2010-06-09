
class Player
  def cmd_purge cme, arg
    # each thing in the room.
    found = []
    in_room.each_stuff [ItemFacade, NpcFacade] { |obj| found << obj }

    found.each do |found_obj|
      in_room.remove found_obj
      found_obj.recycle
    end

    view "You destroyed #{"thing".en.quantify(found.count)}." + ENDL
    return if found.empty?
    view "Among them were " + peek(found) + "." + ENDL  
  end
end

class Player

  def cmd_instance cte, arg
    found = Tag.find_any_obj arg
    if !found
      text_to_player "No object found to instance from." + ENDL
      return
    end

    if !found[0].respond_to?(:instance)
      text_to_player "Error:  No method to instance from #{found[0].class}." + ENDL
      return
    end

    obj = found[0].instance

    case obj
      when ItemFacade
        text_to_player "The glowing outline of #{peek(obj)} appears in your hands as it materializes." + ENDL
        in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], self, [self], 
                  "The glowing outline of <%=other.peek(arg[0])%> appears and then materializes in <%=other.peek(actor)%> hands.", obj)
        self.accept(obj)
      when NpcFacade
        text_to_player "The glowing outline of #{peek(obj)} appears next to you as it materializes." + ENDL
        in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], self, [self],
                  "The glowing outline of <%=other.peek(arg[0])%> appears and then materializes next to <%=other.peek(actor)%>.", obj)
        self.in_room.accept_player(obj)
    end
  end
end

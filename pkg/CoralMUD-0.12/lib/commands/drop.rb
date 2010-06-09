class Player
  def cmd_drop tab,  arg
    view("You drop #{peek(arg)}." + ENDL)
    in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], self, [self], "<%=other.peek(actor)%> drops <%=other.peek(arg[0])%>.", arg)
    drop(arg)
  end
end

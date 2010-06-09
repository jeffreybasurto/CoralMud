class Player
  def cmd_get tab, obj
    obj = [obj].flatten

    rej = obj.select {|o| o.owner == self }
    if !rej.empty?
      obj = obj - rej
      view "You already have #{peek(rej)}." + ENDL
    end

    return if !obj[0]

    view("You get #{peek(obj)}." + ENDL)
    in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], self, [self], "<%=other.peek(actor)%> gets <%=other.peek(arg[0])%>.", obj)

    # do all the real operations after the messages.
    get(obj)
  end
end


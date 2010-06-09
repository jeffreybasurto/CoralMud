class Player
  def cmd_put tab,  arg, *args
    arg = [arg].flatten
    arg2, arg3 = *args
    if arg2 == "into"
      arg2 = [arg3].flatten
    else
      arg2 = [arg2].flatten
    end

    arg = arg - arg2
    if arg.empty?
      view("You can't put items in themselves." + ENDL)
      return
    end

    view("You put #{peek(arg)} in #{peek(arg2[0])}." + ENDL)
    in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0]) || other.can_see(arg[1])"], self, [self], 
                    "<%=other.peek(actor)%> puts <%=other.peek(arg[0])%> in <%=other.peek(arg[1])%>."+ENDL, arg, arg2)
    if arg.is_a? Array
      arg.each do |o|
        self.remove o
        arg2[0].accept o
      end
    end

  end
end


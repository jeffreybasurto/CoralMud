class Player
  # Look command function
  def cmd_look command_table_entry, *args
    arg, arg2 = *args

    if arg == "at"
      arg = arg2
    end
  
    # we're looking at an item specifically.
    if [arg].flatten[0].is_a?(Item) || [arg].flatten[0].is_a?(NPC)
      arg = [arg].flatten[0]
      in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], self, [self],
             "<%=other.peek(actor)%> glances at <%=other.peek(arg[0])%>.", arg)

      view "You look at #{peek(arg)}." + ENDL
      view arg
      return
    end

    # look directly into a bag.
    if arg == "into"
      # select only things that are a container.
      #arg2 = arg2.select {|o|}
      [arg2].flatten.each do |o|
        view "#{peek(o)} contains:" +ENDL
        o.each_stuff do |es|
          view "#{peek(es)}" + ENDL
        end   
      end
      return
    end
    
    arr = [(-5..5), (-1..1)]

    if arg.is_a?(Integer)
      arr = [(-5-arg/2..5+arg/2), (-1-arg/3..1+arg/3)]
    elsif arg.is_a?(String)
      if !arg.exit_code_to_i
        arr = [(-5..5), (-1..1)]
      else
        i = arg.exit_code_to_i
        arr = case i
          when 0 then [(-5..5), (0..2)]
          when 1 then [(-2..8), (-1..1)]
          when 2 then [(-5..5), (-2..0)]
          when 3 then [(-8..2), (-1..1)]
        end
      end
    end
    m = Automap.new in_room, arr
    m.view(self)

    found = []
    # each thing in the room.
    in_room.each_stuff do |obj|
      case obj
      when self
        next
      when ItemFacade
        found << peek(obj, false)
      when Player, NpcFacade
        view "#{peek(obj).capitalize} is here." + ENDL
      end
    end    

    if found.empty?
    elsif in_room.count_stuff == 1
      found[0] = "lonely " + found[0]
      view found.en.conjunction.capitalize + " is here." + ENDL 
    else
      view found.en.conjunction.capitalize + " are here." + ENDL
    end

    if (@editing && !@editing.empty?)
      execute_command("show") # print the editor menu.
    end
  end

end

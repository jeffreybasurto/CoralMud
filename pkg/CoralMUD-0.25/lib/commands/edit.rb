class Player
  ### command to start editing something. 
  def cmd_edit comm_tab_entry, arg
    case arg
    when nil then thing = [in_room]
    when Array then thing = arg
    else
      # valid tag
      thing = Tag.find_any_obj(arg)
      if !thing
        text_to_player("Nothing found to edit." + ENDL)
        return
      end
    end

      # check to see if the security is high enough.
    looking_at = thing[0]
    has_access = false
    loop do
      break if !looking_at 
      if looking_at.respond_to?(:can_access?)
        if looking_at.can_access?(self)
          has_access = true
          break
        end
      end
      if looking_at.respond_to?(:namespace)
        looking_at = looking_at.namespace
      else
        break
      end
    end

    if has_access == false 
      view "You don't have access to edit #{thing[0]}." + ENDL
      if @security.is_set?(:global_editor_access)
        view "Global security clearance used." + ENDL
      else
        log :info, "#{self.name} tried to access #{thing[0]} but didn't have security clearance."+ENDL
        return
      end
    end

    @editing=@editing || []
    @editing.unshift thing[0]

    found = thing.shift
    view "#Gfound> #{found}" +ENDL
    thing.each do |element|
      view "#G#{element}#n" +ENDL
    end
    execute_command("show")
  end
end

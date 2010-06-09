class NPC
  define_creatable
  define_editor :npc_editor
  define_editor_field({:name=>"vtag", :filter=>:filt_to_tag, :type=>:vtag})
  define_editor_field({:name=>"zone", :filter=>:filt_to_area, :type=>:namespace})
  define_editor_field({:name=>"name", :filter=>:filt_none})

  define_editor_field({:name=>"resets",:filter=>:filt_to_reset,
    :proc_fun=>lambda do |ed, ch, obj, arg|
      command = arg[0] # already correct format.  Guarenteed to be a valid direction 0-5.
      argument = arg[1] # What to do that direction.

      case command.downcase
        when "delete"
          # argument should be a valid number in this case.
          argument = Integer(argument) rescue nil
          if argument == nil || !obj.reset_list[argument]
            ch.view "reset delete [number]" + ENDL
            return
          end
          obj.reset_list.delete_at(argument)
          ch.view "Reset deleted." + ENDL
        when "edit"
          # argument should be a valid number in this case.
          argument = Integer(argument) rescue nil

          if argument == nil || !obj.reset_list[argument]
            ch.view "resets edit [number]" + ENDL
            return
          end

          ch.editing.unshift(obj.reset_list[argument])
          ch.view "Editing reset." + ENDL
        when "add"
          if argument == nil
            ch.view "resets add [npc or item vtag]" + ENDL
            return
          end
          found = Tag.find_any_obj(argument)
          if found && (found[0].is_a?(NPC) || found[0].is_a?(Item))
            found = found[0]
          else
            ch.view "That's not a valid room." + ENDL
            return
          end
          obj.create_reset(found.id)
          ch.view "Reset added." + ENDL
        else ch.view "#{command} wasn't valid." +ENDL + "Did you mean: add or edie?" + ENDL

      end
    end,
    :display=>proc do |obj|
      arr = ["#R==========================================================================#n"]

      arr << mxptag("send 'resets add' prompt") + "#R[#Wresets add#R]:" + mxptag('/send') + "   resets add [vtag] "
      count = 0
      obj.reset_list.each do |r|
        arr << mxptag("send 'resets edit #{count}'") + "#R( [#Wresets edit #{count}#R]#{mxptag('/send')}#n #{IDN.lookup(r.target)}"
        count += 1
      end
      arr
    end
  })


  def self.create ch
    npc = self.new
    npc.namespace = ch.in_room.namespace  # have to set it so gen_generic_tag will work correctly.
    npc.assign_tag Tag.gen_generic_tag(npc), ch.in_room.namespace
    npc.gen_idn
    return npc
  end
end

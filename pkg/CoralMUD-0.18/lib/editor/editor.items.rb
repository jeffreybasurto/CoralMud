class Item
  attr_accessor :type_attributes
  define_creatable
  define_editor :item_editor
  define_editor_field({:name=>"vtag", :filter=>:filt_to_tag, :type=>:vtag})
  define_editor_field({:name=>"zone", :filter=>:filt_to_area, :type=>:namespace})
  define_editor_field({:name=>"name", :filter=>:filt_none})
  define_editor_field({:name=>"type", :filter=>:filt_to_itype, 
    :proc_fun=>proc do |ed, ch, obj, arg| 
      found = obj.type_attributes.collect {|att| att.type}

      filtered = (arg.collect {|att| found.include?(att.type) ? nil : att}).compact

      if filtered.empty?
        ch.view "Type already exists on this item." + ENDL
      else
        obj.type_attributes += filtered
        ch.view "Attribute added." + ENDL
      end
    end,
    :display=>proc do |obj|
      types = obj.types
      ["#{mxptag("send type prompt")}#R[#Wtype#R]:#{mxptag('/send')} #n#{if types.empty? then "[none]" else types end}"]
    end
  })

  define_editor_field({:name=>"v",:filter=>:filt_none, :arg_type=>:arg_str,
    :proc_fun=> lambda do |ed, ch, obj, arg|
      args = arg.multi_args

      i = Integer(args[0]) rescue nil

      if i == nil
        ch.view "Not a valid item property." + ENDL
        return
      end

      found = obj.type_attributes[i-1]

      if found == nil
        ch.view "Not a valid item property." + ENDL
        return
      end

      if args[1] == "delete"
        # then we delete this type right now.
        obj.type_attributes.delete_at(i-1) # done
        ch.view "Item property deleted." + ENDL
        return
      end
      
      ch.editing.unshift(found) # edit the one found.
      ch.view "Editing item property." + ENDL
    end,

    :display=>proc do |obj|
      arr = []
      count = 0
      obj.type_attributes.each do |att|
        count += 1
        arr << ["#{mxptag("send v#{count}")}#R[#Wv#{count}#R]:#{mxptag('/send')}#n #{mxptag("send 'v#{count} delete'")}#R[#Wv#{count} delete#R]#n#{mxptag('/send')} #{att.to_s}"]
      end
      arr << ("#R==========================================================================#n")
      arr.flatten
    end
  })

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
      arr = [mxptag("send 'resets add' prompt") + "#R[#Wresets add#R]:" + mxptag('/send') + "   resets add [vtag] "]
      count = 0
      obj.reset_list.each do |r|
        arr << [mxptag("send 'resets edit #{count}'") + "#R( [#Wresets edit #{count}#R]#{mxptag('/send')}#n #{IDN.lookup(r.target)}"]
        count += 1
      end
      arr
    end
  })


  def self.create ch
    item = self.new
    item.namespace = ch.in_room.namespace  # have to set it so gen_generic_tag will work correctly.
    item.assign_tag Tag.gen_generic_tag(item), ch.in_room.namespace
    item.gen_idn
    return item
  end
end


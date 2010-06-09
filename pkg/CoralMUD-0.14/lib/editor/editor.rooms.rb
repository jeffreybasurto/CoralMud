$room_flags = [:hidden]

class Room
  define_creatable
  define_editor :room_editor
  define_editor_field({:name=>"vtag", :filter=>:filt_to_tag, :type=>:vtag})
  define_editor_field({:name=>"zone", :filter=>:filt_to_area, :type=>:namespace})
  define_editor_field({:name=>"name"})
  define_editor_field({:name=>"sector", 
    :proc_fun=>lambda do |ed, ch, obj, arg|
      found = Sector.lookup(arg)
  
      # if it's not found, then we should print a list of sectors.
      if !found
        ch.view "Valid sectors: " + ENDL
        Sector.list.each do |sect|
          ch.view sect.to_s + ENDL
        end
        return
      end

      obj.sector = found.symbol
    end,

    :display=>proc do |obj|
      ["#{mxptag('send sector')}#R[#Wsector#R]:#{mxptag('/send')}#n            "+obj.sector]
    end
  })


  define_editor_field({:name=>"flags", :filter=>:filt_to_flag, :filter_key=>$room_flags, :type=>:flags})

  define_editor_field({:name=>"description",:arg_type=>:arg_none,
    :proc_fun=>proc do |ed, ch, obj, arg|
      ch.editing.unshift(obj.desc)
      ch.view "Editing description." + ENDL
    end,

    :display=>proc do |obj|
      ["#{mxptag('send description')}#R[#Wdescription#R]:#{mxptag('/send')}","#n"+obj.desc,"----"]
    end
  })
  define_editor_field({:name=>"exit", :filter=>:filt_to_exit,
    # proc exits.  I wrote it out like this because it was difficult to read.
    # What do we do when exits command is accessed?  It's filtered by filt_to_exit.  
    :proc_fun=>lambda do |ed, ch, obj, arg|
      direction = arg[0] # already correct format.  Guarenteed to be a valid direction 0-5.
      command = arg[1] # What to do that direction.

      case command.downcase
        when "edit" then ch.editing.unshift(obj.exit_list[direction]); ch.view "Editing exit." + ENDL
        when "link" then ch.view "This is not yet supported." + ENDL 
        when "dig" 
          supplied = nil
          if arg[2]
            supplied = Tag.find_any_obj arg[2]
            if supplied && supplied[0].is_a?(Room)
              supplied = supplied[0]
            else
              ch.view "That's not a valid room." + ENDL
              return
            end
          end
          temp_in_room = ch.in_room
          ch.in_room = obj
          if supplied
            r = ch.buildwalk(direction, supplied)
          else
            r = ch.buildwalk(direction)
          end
          ch.in_room = temp_in_room
          if r
            ch.view "Room created with a two way link." + ENDL
            #ch.editing.unshift(obj.exit_list[direction]);
          end
        else ch.view "#{command} wasn't valid." +ENDL + "Did you mean: edit, link, or dig?" + ENDL
      end
    end,
    # proc to define how we display this field.   It's only needed because we have a non-generic field.
    # Note that if we didn't include this it would not be displayed at all.
    :display=>proc do |obj|
      str = ["#YExit parameters: [edit, dig, link]#n"]
      4.times do |i|
        ex = obj.exit_list[i]
        if ex
          str << (("%-20s" % "#R[#{mxptag('send "&text;"')}#Wexit #{i.exit_code_to_s} edit#{mxptag('/send')}#R]: #{ex.to_s}#w"))
        else
          str << (("%-20s" % "#R[#{mxptag('send "&text;"')}#Wexit #{i.exit_code_to_s} dig#{mxptag('/send')}#R])#w"))
        end
      end
      str << ("#R==========================================================================#n")
      str
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
      arr << ("#R==========================================================================#n")
      arr
    end
  })

  # add delete option
  define_editor_field({:name=>"delete", :arg_type=>:arg_none, :filter=>:filt_none,
    :proc_fun=>proc do |ed, ch, obj, arg|
      ch.execute_command("done") # leave the editor just in time.
      obj.do_delete # rely on the object to implement a way to delete it.
    end,
    :display=>proc do |obj|
      [mxptag('send delete')+ "#R[#WDELETE#R]:" + mxptag('/send') + "       Deletes Entire Room"]
    end
  })
end

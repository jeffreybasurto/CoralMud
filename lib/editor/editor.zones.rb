class Zone
  define_creatable
  define_editor :zone_edit
  define_editor_field({:name=>"vtag", :filter=>:filt_to_tag, :type=>:vtag})
  define_editor_field({:name=>"name", :filter=>:filt_none})
  define_editor_field({:name=>"access", :filter=>:filt_none, 
    :proc_fun=>proc do |ed, ch, obj, arg|
      if obj.can_access?(arg)
        obj.remove_access(arg)
        ch.view "Security access removed for #{ch.peek(arg)}"+ENDL
      else
        obj.add_access(arg)
        ch.view "Security access added for #{ch.peek(arg)}"+ENDL
      end
      log :info, "Security access list changed for #{obj.name}"
    end,
    :display=>proc do |obj|
      ["#{mxptag('send access prompt')}#R[#Waccess#R]:#{mxptag('/send')} #G#{obj.access_list}#n"]
    end

  })
  define_editor_field({:name=>"notes",:arg_type=>:arg_none, :filter=>:filt_none,
    :proc_fun=>proc do |ed, ch, obj, arg|
      ch.editing.unshift(obj.devnotes)
      ch.view "Editing developer notes." + ENDL
    end,

    :display=>proc do |obj|
      ["#{mxptag('send notes')}#R[#Wnotes#R]:#{mxptag('/send')}","#n"+obj.devnotes,"----"]
    end
  })

  def self.create ch
    area = self.new
    area.namespace = nil 
    area.assign_tag Tag.gen_generic_tag(area), nil
    return area
  end

end

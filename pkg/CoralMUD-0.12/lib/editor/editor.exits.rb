$exit_flags = [:soft_door, :has_door, :closed, :locked, :hidden]


class Exit
  define_editor :exit_editor
  define_editor_field({:name=>"flags", :filter=>:filt_to_flag, :filter_key=>$exit_flags, :type=>:flags})
  # add delete option
  define_editor_field({:name=>"delete", :arg_type=>:arg_none, :filter=>:filt_none,
    :proc_fun=>proc do |ed, ch, obj, arg|
      ch.execute_command("done") # leave the editor just in time.
      obj.do_delete # rely on the object to implement a way to delete it.
    end,
    :display=>proc do |obj|
      [mxptag('send delete')+ "#R[#WDELETE#R]:" + mxptag('/send') + "   Deletes Entire Exit"]
    end
    })
end

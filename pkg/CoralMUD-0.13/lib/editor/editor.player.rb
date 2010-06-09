
$extra_security_flags = [:global_editor_access]
$channel_flags = [:say, :tell, :ichat, :iplayer, :icode, :iruby, :language_filter]
class Player
  define_editor :pc_editor
  define_editor_field({:name=>"name"})
  define_editor_field({:name=>"level", :arg_type=>:arg_int})
  define_editor_field({:name=>"password",:hidden=>true})
  define_editor_field({:name=>"channel_flags", :filter=>:filt_to_flag, :filter_key=>$channel_flags, :type=>:flags})
  define_editor_field({:name=>"security", :filter=>:filt_to_flag, :filter_key=>($security_flags+$extra_security_flags).sort, :type=>:flags})
end


# filters for transforming an argument to something else.
class Filter
  include Singleton

  def filt_to_itype str
    found = query_parse(str, $item_types, false, {:name=>:to_s, :id=>:__id__})
    if found.empty?
      return nil
    end

    return found.collect{|t| item_attribute(t) }
  end

  def filt_from_vtag str
    found = Tag.find_any_obj str
    return nil if !found
    found[0].id
  end

  def filt_to_area str, namespace=nil
    found = Tag.find_any_obj str
    if !found
      return nil
    end
    return found[0]
  end

  def filt_to_int str, namespace=nil
    return Integer(str) rescue nil
  end

  def filt_to_tag str, namespace=nil
    s = str.derive_tag.revert_tag # hack to make sure we don't allow name spaces.  It's not preserved over the conversion.
    return [s, namespace]
  end

  def filt_to_flag str, key
    s = str.multi_args # into each word

    return nil if s[0] == nil || key.include?(s[0].downcase.to_sym) == false
    [s[0].downcase.to_sym, s[1]] # return a valid flag and an optional value to set it to.
  end

  def filt_to_reset str
    s = str.split
    if s[0] == nil
      return nil
    end
    return s
  end

  def filt_to_exit old
    s = old.split
    if s[0] == nil || s[0].downcase.exit_code_to_i == nil
      return nil
    end
    s[1] = "edit" if !s[1]
    s[0] = s[0].downcase.exit_code_to_i
    return s
  end

  def filt_none old
    return old
  end
end

EditorFilters = Filter.instance


### Attached to any class that can be edited automatically with the variable "editor_interface"
class Editor
  attr :lookup
  @@editor_list = {}  ### stored across all editors in existance.  Elegant way to have something to check input against.
  
  def initialize name, p, p_on_exit,  c

    @lookup = p 

    @on_exit = p_on_exit

    @@editor_list[name] = self
    @editor_name = name    ### the editors name, such as redit
    
    @editor_commands = [EditorCommand.new("show", nil, :arg_none, :filt_none, proc{|ed, ch| ch.text_to_player("#{ed.display_values ch.editing}") },nil,nil, self),
                        EditorCommand.new("commands", nil, :arg_none, :filt_none, proc{|ed, ch| ch.text_to_player("#{ed.commands_list_get}" + ENDL)}, nil,nil, self),
                        EditorCommand.new("done", nil, :arg_none, :filt_none, 
                                proc{|ed, ch| ch.text_to_player("Leaving editor."+ENDL);e = ch.editing.shift; @on_exit.call(e) if @on_exit}, nil,nil, self)]
  end

  def add_command command_arg
    @editor_commands << command_arg
  end

  def self.list
    @@editor_list
  end

  # return a string to display the current values in the object being edited.
  def display_values objs
    obj = objs[0]
    a = @editor_commands.collect do |c| 
      s = nil
      if c.function != nil
        s = "#R[#{mxptag('send "&text;" prompt')}#W#{c.name}#{mxptag('/send')}#R]:" + ' '*(20 - c.name.length - 3)

        if c.pword_hidden
          s << " #W*****"
        else
          case c.type
            when :flags then s << "#W#{obj.instance_variable_get("@#{c.name}").display_flags(c.key, c.name, 20)}"
            when :namespace then s << "#W#{obj.namespace}"
            else 
              if c.opts[:view_filter]
                s << " #W#{c.opts[:view_filter].call(obj.instance_variable_get("@#{c.name}"))}"
              else
                s << " #W#{obj.instance_variable_get("@#{c.name}")}"
              end
          end
        end
      end
      s
    end
    z = @editor_commands.select {|com| com.proc_display != nil}.collect { |c| c.call_display nil, obj }

    if !z.empty?
      a << "#R=========================================================================="
      a += z
    end

    str = '#R__________________________________________________________________________' + ENDL
    if obj.is_a?(String)
      str<<("#R_%s_" % "#{@editor_name}: #{obj[0..30]}[...]").ljust(74, '_') + ENDL
    else
      str<<("#R_%s_" % "#{@editor_name}: #{obj}".strip_mxp!.upcase).ljust(74, '_') + ENDL
    end

    a.compact!
    str += a.join(ENDL) + ENDL
    str +="#R==========================================================================" + ENDL
    str +="#R[#{mxp('send')}#Wdone#{mxp('/send')}#R]#n" + ENDL
  end

  def commands_list_get
    @editor_commands.collect { |c|  c.name }
  end

  ### selects all commands that match arg even partially. 
  def find_command arg
    @editor_commands.select {|c| c.name==arg} 
  end
end

# a single command in the editor_commands tables per Editor created.
class EditorCommand 
  attr :name, :function, :arg_type, :proc_fun, :proc_display, :key, :type, :pword_hidden, :opts
  def initialize name, function, arg_type, filter, p, d,key, editor, hidden = false, type=:set, pword_hidden=false, opts={}
    @key = key # for passing optional filter arguments.  For example, the correct table for the :filter_flag filter.
    @name = name
    @function = function
    @arg_type = arg_type
    @filter = filter
    @hidden = hidden
    @proc_fun = p
    @proc_display = d
    @editor = editor
    @type = type
    @pword_hidden = pword_hidden
    @opts=opts
  end

  def to_str
    "EditorCommand: #{name}"
  end

  # use this commands overall filter to return the correct type.
  def filter arg, player=nil
    arg = arg.send(@arg_type)

    if @type == :vtag
      return EditorFilters.send(@filter, arg, nil)
    end

    if @key != nil
      EditorFilters.send(@filter, arg, @key)
    else
      EditorFilters.send(@filter, arg)
    end
  end

  def call_display ch, obj
    if @proc_display
      @proc_display.call obj
    end
  end

  def call_fun ch, obj, arg
    if @proc_fun != nil
      @proc_fun.call @editor, ch, obj, arg
    else
      ch.view "Value set." + ENDL
      obj.send(@function, arg)
    end
  end
end

$editor_lookup_procs = {}  # map of editor to procs for looking up values.
                           # this is initialized when you construct the editor.

$loadable_classes = {}
#meta programming to define our editor functions and accessors.
class Class  
  # defines that this class can be created with the create command.
  def define_creatable
    log :debug, "Creatable class: #{self.to_s.downcase}=>#{self}"
    $editable_classes[self.to_s.downcase] = self # all classes that may be edited. 
  end

  # defines that this class can be loaded with the load command.
  def define_loadable
    log :debug, "Loadable class: #{self.to_s.downcase}=>#{self}"
    $loadable_classes[self.to_s.downcase] = self
  end

  def define_editor sym=:none, h={}
    p = h[:lookup]
    p_on_exit = h[:on_exit]
    class_variable_set("@@class_editor", Editor.new(sym.to_s, p, p_on_exit, self))
    define_method("class_editor") do
      self.class.class_variable_get(:@@class_editor)
    end
    if p
      $editor_lookup_procs[sym] = p
    end
  end

  def define_editor_field(*accessors)
    accessors.each do |each_hash|
      a_symbol = each_hash[:name] # The name of the variable
      arg_type = each_hash[:arg_type] || :arg_str  # Type of argument that is expected to be supplied.
      filter = each_hash[:filter] || :filt_none # filter to use
      p = each_hash[:proc_fun] # if this isn't nil we should use it instead of defining a method.
      d = each_hash[:display] 
      key = each_hash[:filter_key]
      type = each_hash[:type] || :set
      hidden_value = each_hash[:hidden] || false      
      opts = each_hash[:opts] || {}
     

      temp = class_variable_get(:@@class_editor);           
      e = temp
      if p
        temp.add_command EditorCommand.new(a_symbol, nil, arg_type, filter, p, d, key, e, false, type, hidden_value, opts)
      else
        temp.add_command EditorCommand.new(a_symbol, "edit_#{a_symbol}".to_sym, arg_type, filter, p, d, key, e, false, type, hidden_value, opts)

        case type
        when :vtag
          define_method("edit_#{a_symbol}".to_sym) do |val|
            #we expect val to be a tag. I.e. a single word
            # possibly:  a.simple.tag 
            if val[1] == nil
              send(:assign_tag, val[0], instance_variable_get('@namespace'))  # object must mix-in virtual tags
            else
              send(:assign_tag, val[0], val[1])
            end
            true
          end
        when :flags
          define_method("edit_#{a_symbol}".to_sym) do |val|
            # we expect val to be an array with a flag and an optional value.
            # If the value is nil we toggle the flag.  If the value is not nil we set the flag to that value.
            temp = instance_variable_get("@#{a_symbol}")
            

            if val[1] == nil
              if temp == nil
                temp = {}
                temp.toggle(val[0])
                instance_variable_set("@#{a_symbol}", temp)
              else
                temp.toggle val[0]
              end
            else
              temp[val[0]] = val[1]
              true
            end   
            # true returned if flag is set.  false if flag is off. 
          end
        when :namespace
          define_method("edit_#{a_symbol}".to_sym) do |val|
            # We can assume the data is already correct coming in.
            reassociate_tag(val) # 
            true
          end
        when :set
          # room.edit_name "Name of a Room"
          define_method("edit_#{a_symbol}".to_sym) do |val|
            # We can assume the data is already correct coming in.
            instance_variable_set("@#{a_symbol}", val)  
            true
          end
        end

      end
    end
  end
end



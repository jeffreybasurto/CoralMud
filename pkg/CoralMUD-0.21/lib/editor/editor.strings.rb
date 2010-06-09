
# attach an editor to be used with the String class.
# It'll need some type of higher level interaction than in other places.
# Because we're not dealing with fields on the string but the string itself.
# So the predefined editing facilities won't work. 
class String
  define_editor :string_edit, {:on_exit=>proc {|obj| obj.finalize_string} }

  define_editor_field({:name=>"append",
    :proc_fun=>lambda do |ed, ch, obj, arg|
      new_str = obj.get_change.gsub('\r\n', '').dup + ENDL + arg # append the line.
      ch.text_to_player("New line appended." + ENDL)
      obj.change(new_str)
    end,
    :display=>proc do |obj|
      ["#n%s" % obj.get_change.display_line_by_line, "#R--------",
       mxptag('send append prompt')+ "#R[#Wappend#R]:" + mxptag('/send') + "  -- append a line to the text."]
    end
  })

  define_editor_field({:name=>"format", :arg_type=>:arg_none,
    :proc_fun=>lambda do |ed, ch, obj, arg|

      new_str = $desc_formatter.format(obj.get_change.dup)
      ch.text_to_player("Text format complete." + ENDL)
      obj.change(new_str.strip)
    end,
    :display=>proc do |obj|
      [mxptag('send format')+ "#R[#Wformat#R]:" + mxptag('/send') + "  -- format the text."]
    end
  })

  define_editor_field({:name=>"replace", 
    :proc_fun=>lambda do |ed, ch, obj, arg|
      a = arg.multi_args # split into array of args.
      if !a[0] || !a[1]
        ch.text_to_player "replace <this text> <with this text>" + ENDL
        return
      end
      new_str = obj.get_change.sub(a[0], a[1])
      if new_str == obj
        ch.text_to_player"No substitution made." + ENDL
        return
      end

      ch.text_to_player("(#{a[0]}) replaced with (#{a[1]})" + ENDL)

      obj.change(new_str)
    end,
    :display=>proc do |obj|
      [mxptag('send insert prompt')+ "#R[#Winsert#R]:" + mxptag('/send') + "  -- replace 'this' 'with this'"]
    end
  })


  define_editor_field({:name=>"replace", 
    :proc_fun=>lambda do |ed, ch, obj, arg|
      a = arg.multi_args # split into array of args.
      if !a[0] || !a[1]
        ch.text_to_player "replace <this text> <with this text>" + ENDL
        return
      end
      new_str = obj.get_change.sub(a[0], a[1])
      if new_str == obj
        ch.text_to_player"No substitution made." + ENDL
        return
      end
      
      ch.text_to_player("(#{a[0]}) replaced with (#{a[1]})" + ENDL)

      obj.change(new_str)
    end,
    :display=>proc do |obj|
      [mxptag('send replace prompt')+ "#R[#Wreplace#R]:" + mxptag('/send') + " -- replace 'this' 'with this'"]
    end
  })


  # add clear option
  define_editor_field({:name=>"clear", :arg_type=>:arg_none, 
    :proc_fun=>proc do |ed, ch, obj, arg|
      # obj is the string
      obj.change("")
      ch.text_to_player "Text cleared." + ENDL
    end,
    :display=>proc do |obj|
      [mxptag('send clear')+ "#R[#Wclear#R]:" + mxptag('/send') + "   -- Clear the entire string."]
    end
    })

  # undo 1 change
  define_editor_field({:name=>"undo", :arg_type=>:arg_none, 
    :proc_fun=>proc do |ed, ch, obj, arg|
      # obj is the string
      obj.undo
      ch.text_to_player "Undo completed." + ENDL
    end,
    :display=>proc do |obj|
      [mxptag('send undo')+ "#R[#Wundo#R]:" + mxptag('/send') + "    -- Undo changes."]
    end
    })

  def get_change
    if @undo_stack && !@undo_stack.empty?
      @undo_stack[0]
    else
      self
    end
  end

  def change str
    @undo_stack = []  if !@undo_stack
  
    # Add the newest string to the stack.   If we decide to revert changes we can pop the queue.
    @undo_stack.unshift str
  end
  
  def undo
    if @undo_stack && !@undo_stack.empty?
      @undo_stack.shift
    else
      nil
    end
  end

  # called to set string equal to the latest revision.
  def finalize_string
    if @undo_stack && !@undo_stack.empty?
      self.replace(@undo_stack[0])
    end

    if defined?(@undo_stack)
      remove_instance_variable(:@undo_stack)
    end
  end

  
  def wrap_text(col = 80)
    self.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/, "\\1\\3\n")
  end

  def display_line_by_line
    s = self.dup
    s = "#W 1. " + s
    count = 1
    s.gsub!(/\r\n|\n|\n\r/) do 
      count += 1
      (ENDL+"#W%2s. " % "#{count}")
    end
    return s
  end

end

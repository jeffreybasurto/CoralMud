class Player
  def cmd_create cte, arg
    if arg.is_a? String
      f = FormatGenerator.new 5
      view "Syntax:  create <type>" + ENDL
      view "Valid types: " + ENDL
      $editable_classes.each_pair do |k, v|
        view "#{k} "
        view f.resume
      end
      view ENDL
      return
    end

    if arg.respond_to? :create
      obj = arg.create(self)
    else
      view "Error:  No method to create from that class." + ENDL
      return
    end

    @editing=@editing || []
    @editing.unshift obj
    view "Created.  You're currently editing #{@editing[0]}." + ENDL
    execute_command("show")
  end
end

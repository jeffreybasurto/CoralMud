class Player
  def cmd_wear ctab, objs
    objs = [objs].flatten

    # select a set based on which could be successfully worn.
    success = objs.select {|a_obj| wear(a_obj) }
    fails = objs - success

    if !success.empty?
      view "You wear #{peek(success)}." + ENDL
    end

    if !fails.empty?
      view "You cannot wear #{peek(fails)}." + ENDL
    end
  end
end

class Player
  def cmd_remove ctab, objs
    objs = [objs].flatten

    # select a set based on which could be successfully worn.
    objs.each do |obj|
      remove(obj)
    end 
    view "You remove #{peek(objs)}." + ENDL
  end
end

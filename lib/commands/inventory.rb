class Player
  def cmd_inventory cte, arg
    count = 0
    found = []
    each_stuff_not_worn do |thing|
      found << peek(thing, false)
      count += 1
    end

    view "You are carrying #{"item".en.quantify(count)}." + ENDL

    if found.empty?

    elsif count_stuff == 1
      found[0] = "lonely " + found[0]
      view "It is " + found.en.conjunction + " indeed." + ENDL      
    else
      view "Among them are "+ found.en.conjunction + "." + ENDL
    end
  end
end

class Player
  def cmd_paint cte, arg
    found = Sector.lookup(arg)
    if !found
      ch.view "Valid sectors: " + ENDL
      Sector.list.each do |sect|
        ch.view sect.to_s + ENDL
      end
      return
    end

    view "Painting all joined rooms." + ENDL

    target = in_room.sector
    count = 0
    # parse each room in bfs pattern and only commit rooms which actually are in the target radius.
    in_room.each_bfs({:full_traverse=>true}) do |current_room|
      current_room.sector = found.symbol 
      count += 1
    end

    view "#{count} rooms changed to sector type #{found}" + ENDL

  end
end

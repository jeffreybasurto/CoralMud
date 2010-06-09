# path node
class PathNode
  attr_accessor :to_dir, :to_node, :room, :old
  def initialize dir, node, room #construct it and build using the opposite supplied direction
    @to_dir = nil 
    @to_dir = dir.exit_code_rev if dir != nil

    #next node, no link back
    @to_node = node

    # what room.
    @room = room

    @old = nil
  end

  def path_to_directions
    c = self
    arr = []
    while c.to_dir != nil
      arr << c.to_dir.exit_code_rev.exit_code_to_s
      c = c.to_node
    end
    return arr
  end

  # draw on the map.
  def draw map
    c = self
    prev = nil

    while c != nil
      c.old = map.pallete[c.room.map_x][c.room.map_y]
      
      if prev != nil
        track_tag = nil
        if prev.to_dir == 0
          case c.to_dir 
            when 0 then track_tag = :track_ns
            when 1 then track_tag = :track_ne
            when 3 then track_tag = :track_nw
          end
        elsif prev.to_dir == 1
          case c.to_dir
            when 0 then track_tag = :track_ne
            when 1 then track_tag = :track_we
            when 2 then track_tag = :track_nw 
          end
        elsif prev.to_dir == 2
          case c.to_dir
            when 1 then track_tag = :track_nw
            when 2 then track_tag = :track_ns
            when 3 then track_tag = :track_ne
          end
        elsif prev.to_dir == 3
          case c.to_dir
            when 0 then track_tag = :track_nw
            when 2 then track_tag = :track_ne 
            when 3 then track_tag = :track_we
          end
        end
        map.write_pallete(c.room.map_x, c.room.map_y, track_tag)
      else
        map.write_pallete(c.room.map_x, c.room.map_y, :track_found) #the target node
      end
      case c.to_dir
        when "east".exit_code_to_i  then map.write_pallete(c.room.map_x+1, c.room.map_y, :track_we); map.write_pallete(c.room.map_x+2, c.room.map_y, :track_we)
        when "west".exit_code_to_i  then map.write_pallete(c.room.map_x-1, c.room.map_y, :track_we); map.write_pallete(c.room.map_x-2, c.room.map_y, :track_we)
        when "south".exit_code_to_i then map.write_pallete(c.room.map_x, c.room.map_y-1, :track_ns); map.write_pallete(c.room.map_x, c.room.map_y-2, :track_ns)
        when "north".exit_code_to_i then map.write_pallete(c.room.map_x, c.room.map_y+1, :track_ns); map.write_pallete(c.room.map_x, c.room.map_y+2, :track_ns)
      end
      prev = c
      c = c.to_node 
    end
  end

  # remove what was already made.
  def undraw map
    c = self
    while c != nil
      map.write_pallete(c.room.map_x, c.room.map_y, c.old)

      case c.to_dir
        when "east".exit_code_to_i  then map.write_pallete(c.room.map_x+1, c.room.map_y, c.old); map.write_pallete(c.room.map_x+2, c.room.map_y, c.old) 
        when "west".exit_code_to_i  then map.write_pallete(c.room.map_x-1, c.room.map_y, c.old); map.write_pallete(c.room.map_x-2, c.room.map_y, c.old)
        when "south".exit_code_to_i then map.write_pallete(c.room.map_x, c.room.map_y-1, c.old); map.write_pallete(c.room.map_x, c.room.map_y-2, c.old)
        when "north".exit_code_to_i then map.write_pallete(c.room.map_x, c.room.map_y+1, c.old); map.write_pallete(c.room.map_x, c.room.map_y+2, c.old)
      end

      c = c.to_node
    end
  end

end

class AreaMap
  attr_accessor :pallete, :rooms

  def initialize(room, size)
    @pallete = []
    size = 300
    z = 0
    @rooms = {}
    while z < size
      z = z + 1
      @pallete[z] = []
    end

    produce_map(room, size)
  end

  def write_pallete(x, y, value)
    @pallete[x][y] = value
  end

  def AreaMap.exitoffsetx x, dir
    case dir
      when 0 then return x
      when 1 then return x+3
      when 2 then return x
      when 3 then return x-3
    end
  end

  def AreaMap.exitoffsety y, dir
    case dir
      when 0 then return y+3
      when 1 then return y
      when 2 then return y-3
      when 3 then return y
    end
  end

  def AreaMap.offsetx x, dir
    case dir
      when 0 then return x
      when 1 then return x+1
      when 2 then return x
      when 3 then return x-1
    end
  end

  def AreaMap.offsety y, dir
    case dir
      when 0 then return y+1
      when 1 then return y
      when 2 then return y-1
      when 3 then return y
    end
  end

  # pathfind using existing room keys.
  def AreaMap.pathfind(start, target)
    pnlist = {}
    pnlist[start] = PathNode.new(nil, nil, start)
    
    start.each_bfs do |r|
      pn = pnlist[r]
      #returns the pn to the caller.
      return pn if r == target # found

      # 4 exits
      4.times do |i|
        if r.exit_list[i] != nil
          if pnlist[r.exit_list[i].towards_room.gri] == nil
            pnlist[r.exit_list[i].towards_room.gri] = PathNode.new(i, pn, r.exit_list[i].towards_room.gri) # link it back to this node
          end
        end
      end
    end
    return nil
  end

  def AreaMap.find_room(room, a)
    x, y = room.map_x, room.map_y 

    a[0], a[1] = (a[0] * 3 + x), (a[1] * 3 + y)

    room.each_dfs do |r|
      return r if r.map_x == a[0] && r.map_y == a[1]
    end
  end

  def produce_map(room, size) 
    room.map_x, room.map_y = size/2, size/2
    cca =  [["east".exit_code_to_i, "north".exit_code_to_i],
            ["west".exit_code_to_i, "north".exit_code_to_i],
            ["west".exit_code_to_i, "south".exit_code_to_i],
            ["east".exit_code_to_i, "south".exit_code_to_i]]

    @rooms = {}

    room.each_bfs do |r|
      
      x, y = r.map_x, r.map_y
      @rooms[r.vnum] = r 

      write_pallete(x, y, r.sector)
      # do all of our circular checks. If it returns true we need to set the pallete
      cca.each do |c| 
        if (r.circular_check(c))
          write_pallete(AreaMap.offsetx(x, c[0]), AreaMap.offsety(y, c[1]), r.sector)
        else
          write_pallete(AreaMap.offsetx(x, c[0]), AreaMap.offsety(y, c[1]), (r.sector.to_s+"w").to_sym)
        end
      end

      4.times do |i|
        if r.exit_list[i] != nil
          c = r.sector
          r.exit_list[i].towards_room.gri.map_x, r.exit_list[i].towards_room.gri.map_y = AreaMap.exitoffsetx(x, i), AreaMap.exitoffsety(y, i)
        else
          c = (r.sector.to_s+"w").to_sym # wall
        end
        write_pallete(AreaMap.offsetx(x, i), AreaMap.offsety(y,i), c)
      end
    end
  end

end



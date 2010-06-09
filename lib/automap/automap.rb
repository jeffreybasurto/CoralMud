
class Automap
  # syntax:  Automap.new(some_room, [(-10..10), (-5, 5)])  
  #  rng_arr should be an array of two ranges.  The map'd x/y range from origin, or the room passed.
  def initialize room, rng_arr, options={:full_traverse=>false, :range=>rng_arr}
    @pallete = {} 
    @rng_arr = rng_arr
    options[:yield_range] = rng_arr # passes this to the algorithm that determines what is yielded.
    build_map(room, options)
  end

  #construct the pallete based on the first room.  Use a bfs. 
  def build_map(room, opts={:full_traverse=>false})
    # commit this room to the map.
    def write_room(xy, croom)
      node_data = {:room=>croom, :path=>croom.sector, :wall=>Sector.lookup(croom.sector).symbolw}
      croom.each_dir do |ex|
        node_data[ex.direction.exit_code_to_s.to_sym] = ex
      end
      @pallete[xy] = node_data # commit our changes.      
    end

    # parse each room in bfs pattern and only commit rooms which actually are in the target radius.
    room.each_bfs(opts) do |current_room, context|
      coord = [context[:x], context[:y]] # this rooms coordinate position. 
      write_room coord, current_room
    end
  end

  # used to find rooms in relationship to the seed room.  
  # returns the node containing the data for this coordinate.
  def find xy
    @pallete[xy]
  end

  # convert a section of the pallete over so we can view it.
  # exammple:  map.view ch
  # defaults to the same view range as it was constructed with.
  def view ch, rng_arr=@rng_arr
    xrng, yrng = @rng_arr # bust the array to access it easier.    
    main_str = ""

    # convert the symbol for the pass into a line that can be translated into a string with gsub.  
    def value_for_pass this_node, p, xy, player
      str = '000'
      str = '010' if p == 1 # if it's the second pass.
      return '   ' if !this_node
      case p
        when 0 
          if this_node[:north]
            str[1] = '1' 
            str[0] = '1' if (this_node[:west] && !this_node[:west].flags.is_set?(:has_door)) &&
                            (!this_node[:north].flags.is_set?(:has_door))
            str[2] = '1' if (this_node[:east] && !this_node[:east].flags.is_set?(:has_door)) &&
                            (!this_node[:north].flags.is_set?(:has_door))
            str = '040' if this_node[:north].flags_state.is_set?(:closed)
          end
        when 1
          if this_node[:west]
            str[0] = '1' 
            str[0] = '5' if this_node[:west].flags_state.is_set?(:closed)
          end
          str[1] = '2' if xy == [0,0]
          str[1] = '3' if this_node[:room] == player.in_room
          str[2] = '1' if this_node[:east]
          str[2] = '5' if this_node[:east] && this_node[:east].flags_state.is_set?(:closed)

        when 2 
          if this_node[:south]
            str[1] = '1' 
            str[0] = '1' if this_node[:west] && !this_node[:west].flags.is_set(:has_door) && !this_node[:south].flags.is_set?(:has_door)
            str[2] = '1' if this_node[:east] && !this_node[:east].flags.is_set(:has_door) && !this_node[:south].flags.is_set?(:has_door)
            str = '040' if this_node[:south].flags_state.is_set?(:closed)
          end
      end
      str.gsub!(/[0]/, this_node[:wall].sect_to_str)
      str.gsub!(/[1]/, this_node[:path].sect_to_str)
      str.gsub!(/[3]/, :sect_self.sect_to_str)
      str.gsub!(/[2]/, :track_found.sect_to_str)
      str.gsub!(/[4]/, :door_ns.sect_to_str)
      str.gsub!(/[5]/, :door_we.sect_to_str)
      return str
    end

    ground_zero = @pallete[[0,0]][:room] # the room at ground zero.


    if ground_zero.name != DEFAULT_STRING
      name = "[#B"+ ground_zero.name + "#D]"
    else
      name = "-"
    end

    # actual display logic
    ch.text_to_player ("#{ground_zero}" + ENDL) if ch.is_imm?
    ch.text_to_player ("#W O #D,%s, #WO" % name.center(xrng.count*3-2, '-')) + ENDL
    (yrng).to_a.reverse.each do |y|
      3.times do |pass|
        main_str << "#D|||"
        xrng.each do |x|
          # 3 blocks per pass to form the 3x3 mapper.
          this_node = @pallete[[x, y]]
          if pass == 2 && y == yrng.first && (x == xrng.first || x == xrng.first+1)
            next if x == xrng.first+1
            main_str << "#RExits:"
          else
            main_str << value_for_pass(this_node, pass, [x,y], ch)
          end
        end
        main_str << "#D|||" + ENDL
      end
    end
    buf = "#D[#B"
    if ch.in_room.exit_list.empty?
      buf << " None#D ]"
    else
      ch.in_room.exit_list.each do |xexit|
        if xexit
          buf << (" #{mxptag('send')}#W%s#{mxptag('/send')}" % xexit.direction.exit_code_to_s)
        end
      end
      buf << "#D ]"
    end
    main_str << ("#W @ #D'%s'#W @\r\n" % "#{buf}".center(xrng.count*3-2, '-'))

    ch.text_to_player main_str
  end


  def self.offset xy, dir
    arr = xy.dup
    case dir
    when 0 then arr[1] += 1
    when 1 then arr[0] += 1
    when 2 then arr[1] -= 1
    when 3 then arr[0] -= 1
    end
    return arr
  end
end





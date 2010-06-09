class Integer
  def gri
    get_room_index self
  end
end

# Example:  sect_city or sect_forest
class Sector 
  attr_accessor :name, :symbol, :symbolw, :path_options, :wall_options
  @@sector_hash = {} # for fast lookups using symbols.  Was considerably more efficient.
  @@map_tiles = {} # for fast lookup of map tile. 
  def initialize n, sym, wall_op, path_op
    @name = n
    @symbol = sym
    @symbolw = (sym.to_s + "w").to_sym
    @wall_options = wall_op
    @path_options = path_op
    @@sector_hash[sym] = self # add this to the list.
    log :debug, "Loading sector: #{@name}"
  end

  def to_s
    "#{@name} (#{@wall_options} #{@path_options})"
  end

  # lookup a sector given a name or a symbol
  def self.lookup name
    if name.is_a? Symbol
      #log :debug, "Sector.sector_lookup(#{name}) returns #{@@sector_hash[name].to_str}"
      found = @@sector_hash[name]

      if found == nil
        temp = @@sector_hash.values
        temp = temp.select {|v| v.symbolw == name}
        found = temp[0]
      end
      return found
    end
    name.downcase!
    # select from list
    temp = @@sector_hash.values # array of values
    temp = temp.select {|v| v.name.start_with?(name) }
    
    return temp[0]
  end
end

# Room sector definitions.
#            NAME          SYMBOL       [[Color], north/south, east/west],   
# Sector.new("name",      :sect_symbol, [[], wall tiles],           [[], path tiles.
begin
  log :debug, "Loading sector definitions."
  Sector.new("forest",    :sect_forest, [['g', 'G'], ['|'], '-'],     [['w'], ['.']])
  Sector.new("fancy",     :sect_fancy,  [['P'], ['##'], '##'],        [['C'], ['.']])
  Sector.new("city",      :sect_city,   [['W'], ['##'], '##'],        [['C'], ['.']])
  Sector.new("inside",    :sect_inside, [['n'], ['##'], '##'],        [['D'], ['.']])
  Sector.new("fountain",  :sect_fount,  [['W'], ['##']],               [['B'], ['0']])
  Sector.new("alley",     :sect_alley,  [['y', 'Y'], ['|'], '-'],     [['w'], ['.']])
  Sector.new("water",     :sect_water,  [['b','B'], ['##'], '##'],    [['b', 'B'], ['~', '-']])
  Sector.new("beach",     :sect_beach,  [['Y'], ['##'], '##'],        [['y', 'Y'], ['.']]) 
  Sector.new("hills",     :sect_hills,  [['g', 'G'], ['~'], '~'],     [['y'], ['.']])
  Sector.new("dock",      :sect_dock,   [['y'], ['=']],               [['D'], ['.']])
  Sector.new("void",      :sect_void,   [['n'], [' '], ' '],          [['x'], [' ']])
rescue Exception=>e
  log :error, "Sector table failed to load properly."
  log_exception e
end

class Area
  attr_accessor :maps, :number, :rooms
  def initialize(n) 
	  @number = n
	  @rooms = []
	  $area_list[n] = self
  end

  # find a free vnum within the given area
  def Area.gen_vnum area_num
    if (area_num == 0)
      real_n = 1
    else
      real_n = area_num * 1000
    end

    while (real_n < ((area_num + 1) * 1000))
      if !get_room_index(real_n)
        return real_n
      end
      real_n += 1
    end

    return nil
  end

    
  # Adds a room to this area. The room has to be within the vnum range.
  def inject_room r 
	  @rooms[r.vnum % 1000] = r
  end
end

class Exit
  attr_accessor :towards_room, :from_room, :direction, :flags                  
  attr_accessor :flags_state # isn't saved and is used to determine things like closed doors, etc

  def initialize(xnum=nil,xnum2=nil,dir=nil)
    @flags = {} #empty
    @flags_state = {}
    return if xnum == nil
    
    @direction = dir
    @towards_room = get_room_index(xnum) || xnum
    @from_room = get_room_index(xnum2) || xnum2

    @from_room.exit_list[dir] = self if @from_room.is_a?(Room)
  end

  def open
    @flags_state.toggle(:closed)
    oe =  @towards_room.gri.exit_list[@direction.exit_code_rev] 
    if oe && oe.towards_room.gri == @from_room.gri
      oe.flags_state.toggle(:closed)
    end
  end
  def close
    @flags_state.toggle(:closed)
    oe =  @towards_room.gri.exit_list[@direction.exit_code_rev]
    if oe && oe.towards_room.gri == @from_room.gri
      oe.flags_state.toggle(:closed)
    end
  end

  # remove the exit.
  def do_delete
    log :debug, "exit #{@directon} deleted"
    4.times do |x|
      ex = @from_room.exit_list[x]
      next if !ex
      if ex == self
        @from_room.exit_list[x] = nil
        return
      end
    end
  end

  def to_s
    "#{@towards_room} #{@from_room} #{@directon}"
  end

  def enter xplayer
    xplayer.from_room
    
    if @from_room.is_a?(Integer)
      @from_room = get_room_index(@from_room)
    end
    if @towards_room.is_a?(Integer)
      @towards_room = get_room_index(@towards_room)
    end

    @from_room.text_to_room "#{xplayer.name} leaves #{@direction.exit_code_to_s}." + ENDL
    @towards_room.text_to_room "#{xplayer.name} has arrived." + ENDL

    @towards_room.accept_player(xplayer)
    xplayer.execute_command("look");
  end  
end


# a single room.
class Room 
  attr_accessor :vnum, :exit_list, :people, :area
  attr_accessor :name, :sector, :flags, :desc 

  include CoralMUD::FileIO # standard saving mechanisms.

  def initialize xnum=nil
    # Instance variables  
    @name = "Default Name"
    @sector = :sect_city
    @desc = "There is little unique to be seen here."
    @flags = {}
    @people = []
    @vnum = xnum
    @exit_list = [nil, nil, nil, nil, nil, nil]

    $room_list << self

    associate_with_area if @vnum != nil
  end

  # unlink the room completely.  
  def do_delete
    moved = []
    # evacuate the room.
    self.people.each do |person|
      # send them to a safe vnum...we're going to use vnum 1
      person.go_anywhere
      moved << person
    end

    4.times do |i|
      ex = self.exit_list[i]
      next if ex == nil

      log :debug, "ex #{ex.direction} deleted"

      if ex.towards_room.gri.exit_list[ex.direction.exit_code_rev]      
        if ex.towards_room.gri.exit_list[ex.direction.exit_code_rev].towards_room.gri == self # if it's the same room as being deleted we delete 
          ex.towards_room.gri.exit_list[ex.direction.exit_code_rev].do_delete
        end
      end
      ex.do_delete
    end

    moved.each do |p|
      p.execute_command("look")
    end

    a = @vnum / 1000
    $area_list[a].rooms[@vnum % 1000] = nil # unlinked from main list.
  end

  def associate_with_area
    a = area_lookup(@vnum)
    a = Area.new(@vnum/1000) if a == nil
    a.inject_room self
    @area = a
  end

  def to_s
    "Room: #{vnum}"
  end

  def to_configure_properties
    ['@name', '@vnum', '@sector', '@exit_list']
  end

  #save pfile
  def save_room
    save_to_file "data/rooms2/%d.yml" % @vnum
  end

  def self.load_rooms
    log :debug, "Load_rooms: Loading all rooms."

    rfiles = File.join("data/rooms2", "*.yml")

    Dir.glob(rfiles).each do |a_file|
      room = Room.new()
      room.load_from_file(a_file) # loads each room file.
      room.associate_with_area # Must be done after we have the vnum
    end
  end

  def data_transform_on_load version, map
    # transform :exit_list from an array of  
    ar = map["@exit_list"]
    exits = [nil, nil, nil, nil, nil, nil] # all nil
    while !ar.empty? 
      each_arr = ar.shift
      dir, toward_room, flags = *each_arr

      exits[dir] = Exit.new()
      exits[dir].towards_room = toward_room
      exits[dir].from_room = self  
      exits[dir].direction = dir
      exits[dir].flags = flags
      exits[dir].flags_state = flags.dup # set the flags state
    end
    map["@exit_list"] = exits
    return map
  end

  def data_transform_on_save map
    ex = map["@exit_list"] # transform the exit_list into something we can save more reliably.
    arr = []
    ex.each do |e|
      next if e == nil
      arr << [e.direction, e.towards_room.gri.vnum, e.flags]
    end
    map["@exit_list"] = arr
    return map
  end

  # returns self
  def gri
    self
  end

  # does a circular exit check.
  def circular_check a
    return false if (self.exit_list[a[0]] == nil || self.exit_list[a[1]] == nil)
    return false if (self.exit_list[a[0]].towards_room.gri.exit_list[a[1]] == nil || self.exit_list[a[1]].towards_room.gri.exit_list[a[0]] == nil)
    return false if ((r = self.exit_list[a[0]].towards_room.gri.exit_list[a[1]].towards_room.gri) != self.exit_list[a[1]].towards_room.gri.exit_list[a[0]].towards_room.gri)
    return r
  end

  # for each direction in a room that exists.
  def each_dir
    self.exit_list.each do |e|
      yield e if e
    end
  end
  # do a dfs search with a code block
  def each_bfs (option_hash={:full_traverse=>true})
    def adjust_context context, dir
      con = context.dup
      case dir
      when 0 then con[:y] += 1
      when 1 then con[:x] += 1
      when 2 then con[:y] -= 1
      when 3 then con[:x] -= 1
      end
      return con
    end
    color_list, white_list = [], []
    full_traverse = option_hash[:full_traverse] 
    yield_x_range, yield_y_range = option_hash[:yield_range]

    # white list contains data to yield and process each pass.
    white_list << [self, {:x=>0, :y=>0}]
    color_list << self

    # while we still have something to act upon process it.
    # And yield the result to our block of code.
    while !white_list.empty?
      r, context = white_list.shift()

      yield(r, context) if yield_x_range === context[:x] && yield_y_range === context[:y]

      r.each_dir do |e|                 
        next if full_traverse == false && (e.flags_state.is_set(:soft_door) || e.flags_state.is_set(:closed))
        if !color_list.include?(e.towards_room.gri)
          white_list << [e.towards_room.gri, adjust_context(context, e.direction)]
          color_list << e.towards_room.gri 
        end
      end
    end
    return nil
  end

  # do a dfs search with a code block
  def each_dfs
    color_list, white_list = [], []

    white_list << self
    color_list << self

    while !white_list.empty?
      r = white_list.pop()

      # do some code for each room found in the BFS.
      yield r

      r.each_dir do |e|
        if !color_list.include?(e.towards_room.gri)
          white_list << r.exit_list[i].towards_room.gri
          color_list << r.exit_list[i].towards_room.gri
        end
      end
    end
    return nil
  end


  # Create new rooms. Connect them. Nil is valid 
  # By default direction is unset. If no direction both must exist.
  # Also, input should havbeen checked by now.
  def Room.dig_rooms(rvnum1, rvnum2, direction)
    if direction >= 6 || direction < 0
      return false #failed
    end

    # lookup 2 rooms.
    r1, r2 = get_room_index(rvnum1), get_room_index(rvnum2)

    # if either is nil now set it up.
    r1 = Room.new(rvnum1) if !r1
    r2 = Room.new(rvnum2) if !r2

    # creates exits with hook back
    Exit.new(rvnum2, rvnum1, direction)
    Exit.new(rvnum1, rvnum2, direction.exit_code_rev)

    return r2
  end

  def accept_player(player)
    @people << player
    player.in_room = self
  end

  def remove_player(player)
    @people.delete player
    player.in_room = nil
  end

  #method to send to every character in the room.
  def text_to_room txt
    people.each do |p| p.text_to_player(txt) end
  end
end

def save_all_rooms
  $room_list.each do |r|
    r.save_room
  end  
end

def area_lookup num
  t = num / 1000
  return $area_list[t]
end


# a zone is a namespace for rooms and information a specific area.
class Zone
  attr_accessor :name, :access_list, :devnotes
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # virtual tag system included.

  def initialize
    @name = DEFAULT_STRING
    @devnotes = "No notes."
    @access_list = []
  end

  def to_configure_properties
    ['@name', '@vtag', '@devnotes', '@access_list']
  end

  def to_s
    mxptag("send 'edit #{Tag.full_tag(self)}'") + "[Zone #{@vtag}]" + mxptag("/send")
  end

  def add_access ch
    @access_list << case ch
    when Player then ch.name
    when String then ch
    end
  end

  def remove_access ch
    access_token = case ch
    when Player then ch.name
    when String then ch
    end
    
    @access_list.delete access_token
  end

  def can_access? ch
    case ch
    when Player then @access_list.include?(ch.name)
    when String then @access_list.include?(ch)
    end
  end

  def self.load_zones
    f = File.open('data/areas/zone_list.txt', 'r') 
    arr = f.readlines
    log :info, "Loading all zones."
    arr.each do |a_file|
      a_file = "data/areas/#{a_file.strip}"
      z = Zone.new()
      z.load_from_file(a_file) # loads each room file.
      z.reassociate_tag() # Must be done because initializer is not called for the vtag object.
      log :debug, "Loading zone: #{z.vtag.to_s}"
    end
  end

  def self.save_all
    arr = [] # list of all file paths
    #loop through all Zone found. 
    Tag.search_class Zone do |z|
      arr << z.save_zone 
    end

    File.open('data/areas/zone_list.txt', 'w') do |f| 
      arr.each {|str| f.puts str }
    end
  end

  def save_zone
    save_to_file "data/areas/%s.yml" % @vtag.to_s
    return "%s.yml" % @vtag.to_s
  end

  # doing something arcane here.   We want the rooms to be saved inside of map.  So we're going to just in time
  # throw in a value that doesn't exist on a zone but we will associate with it anyways called @rooms.
  # The variable never exists anywhere but on the transformation hash that is dumped to file.
  # When it's loaded back we'll separate the rooms from the area's actual data and the variable never gets used.
  def data_transform_on_save map
    arr = []  # array of config datas for rooms.
    # search and find every room that belongs to this area.
    Tag.search_namespace(self) do |found|
      next if !found.is_a? Room
      arr << found.gen_configure
    end
    map['@rooms'] = arr # rooms will get saved to file as part of this area.

    objarr = []
    Tag.search_namespace(self) do |found|
      next if !found.is_a? Item
      objarr << found.gen_configure
    end
    map['@items'] = objarr

    arr = []
    Tag.search_namespace(self) do |found|
      next if !found.is_a? NPC
      arr << found.gen_configure
    end
    map['@npcs'] = arr

    return map
  end

  # Now we need to use the data @rooms at the last minute as explained above when it's loading.
  # Each element of the array for @rooms is a room that needs to be loaded into the game.
  def data_transform_on_load version, map
    arr = map['@rooms']    
    arr.each do |r|
      r['@namespace'] = self # this is its namespace.
      room = Room.new()
      room.configure(r) # loads each room file.
      room.associate_with_area # Must be done after we have the vnum
    end
    map['@rooms'] = nil

    items = map['@items']
    items.each do |oarr|
      oarr['@namespace'] = self       
      obj = Item.new()
      obj.configure(oarr)
    end

    npcs = map['@npcs']
    npcs.each do |m|
      m['@namespace'] = self
      npc = NPC.new()
      npc.configure(m)
    end
    map['@npcs'] = nil  

    map['@items'] = nil
    return map
  end


end



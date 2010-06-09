
class Player
  attr_accessor :pathtarget, :clas, :race, :sign, :traits, :flags, :socket, :name, :password, :level, :command_table, :channel_flags,
                :editing
  include Movable  ### Include this to give this class the property of being able to be placed in rooms.
  include CoralMUD::FileIO ### Players can be saved.  This also implies Readable
  
  @@version = 1 # Current version.  This can be increased to make changes to the save structure.
                # This is only required to change if there's a particular change in old variables/structure.

  def initialize
    # use conditional initialization
    @command_table  = CommandTable.new

    @socket         = nil
    @name           = nil
    @password       = nil
    @level          = 1
    @flags          = []
    @pathtarget     = nil
    @channel_flags  = {}

    @editing        = []

    ### Will probably remove these 4.
    @clas         = nil
    @race         = nil
    @sign         = nil
    @traits       = nil

    ### Inventory 
    @inventory    = nil
  end

  # saved instance variables.  Called by writable module.
  def to_configure_properties
    ['@name', '@password', '@level', '@channel_flags', '@clas', '@race', '@traits', '@sign']
  end

  # hook to configure for versioning.  This method doesn't need to be defined if
  # we aren't going to version manage.  When we change versioning we can edit this.
  def version_config version, data
  end

  #save pfile
  def save_pfile 
    save_to_file ("players/%s.yml" % @name.downcase.capitalize)
  end

  #load pfile based on name passed.  return the new ch.
  def self.load_pfile passed_name
    ch = Player.new
    ch.load_from_file("players/#{passed_name.downcase.capitalize}.yml")
    return ch
  end

  def go_anywhere
    found = nil

    in_room.exit_list.each do |ex|
      next if ex == nil
      ex.enter(self)
      return
    end

    in_room.remove_player(person)
    r = get_room_index(1)
    if r == nil
      r = goto_make_room 1
    end
    r.accept_player(person)
  end

  def is_imm?
    @level >= LEVEL_IMM 
  end

  def is_admin?
    @level == LEVEL_ADMIN
  end

  def text_to_player txt
    if @socket
      @socket.text_to_socket txt
    end
  end

  def free_player
    $dplayer_list.delete self
    from_room if in_room != nil
    @socket.player = nil if @socket
  end
end
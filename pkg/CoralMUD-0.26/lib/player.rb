class Player
  include CoralMUD::HasStuff ### Makes this a generic container for any stuffs.   At the time of adding this it was for objects to be carried.
  include CoralMUD::LivingEntity
  include CoralMUD::FileIO
  include DataMapper::Resource
  
  before :save do
    log :info, "saving #{self} to database."
  end

  property :id, Serial
  property :name, String
  property :password, String
  property :level, Integer, :default=>1
  property :extra_data, Text

  has n, :messages

  attr_accessor :pathtarget, :clas, :race, :sign, :traits, :socket,:reply_to, :editing, :security
  attr_writer :flags, :security, :channel_flags

  @@version = 1 # Current version.  This can be increased to make changes to the save structure.
                # This is only required to change if there's a particular change in old variables/structure.


  # saved instance variables.  Called by writable module.
  def to_configure_properties
    ['@security', '@channel_flags', '@clas', '@race', '@traits', '@sign', '@stuff']
  end

  def security; @security ||= {}; end
  def flags; @flags ||= [];  end
  def channel_flags; @channel_flags ||= {}; end

  # hook to configure for versioning.  This method doesn't need to be defined if
  # we aren't going to version manage.  When we change versioning we can edit this.
  def version_config version, data
  end

  def data_transform_on_save map
    # stuff needs to be get_configure
    temp_stuff = []
    each_stuff do |item|
      temp_stuff << item.gen_configure
    end
    map['@stuff'] = temp_stuff
    return map
  end

  def data_transform_on_load v, map
    # transform each item facade.
    arr = map['@stuff']
    arr.each do |i|
      item = ItemFacade.new(nil, false)
      item.configure(i) # loads each room file.
    
      self.accept item
    end
    map.delete '@stuff'

    return map
  end
end

class NPC
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # vtags and indexing
  include IDN
  include Resets

  attr_reader :name, :flags

  def to_configure_properties
    ['@name', '@vtag', '@id', '@_reset_list']
  end


  def initialize
    @name = DEFAULT_STRING
  end

  def to_s
    mxptag("send 'edit #{Tag.full_tag(self)}'") + "[NPC #{@vtag}]" + mxptag("/send")
  end

  def instance 
    mob = NpcFacade.new(self)
    mob.copy_resets(reset_list)
    mob.reset
    return mob
  end

  def data_transform_on_save map
    vtag = map['@vtag']
    if vtag
      map['@vtag'] = vtag.to_s
    end
    return map
  end


  def data_transform_on_load version, map
    if !map['@id']
      gen_idn
      map['@id'] = @id
    end
    @id = map['@id']
    register_idn

    vtag = map['@vtag']
    if vtag
      assign_tag vtag, map['@namespace']
      vtag = @vtag
      map['@vtag'] = vtag
    end
    return map
  end
end

module ScriptInterface
  # script methods unique to Npc instances.
  module NpcMethods
    def move arg
      # move the npc to a very specific room based on vtag.
      if arg.is_a? String

      elsif arg.is_a? Room # move them here if it's a room.

      end
    end
  end
end


class NpcFacade < Facade
  attr_facade :name

  include CoralMUD::HasStuff
  include CoralMUD::LivingEntity
  include ScriptInterface::NpcMethods
  include Resets

  def initialize thing
    super thing
    @in_room = nil
  end

  def to_s
    self.name
  end

  def short_desc
    self.name
  end

  # remove this specific NPC from the gamespace.
  # Any tidying up for when a NPC exits the game should be done here.
  def remove_from_gamespace
    # remove it from the room it's in.
    self.from_room 
    self.recycle 
    # Possibly in the future return all switches. I.e. an admin taking over an NPC body.
  end

  @@corpse_proto = nil
  # make a corpse out of this npc.
  def make_corpse
    if @@corpse_proto == nil
      @@corpse_proto = Tag.find_any_obj("do.not.change::corpse.prototype")[0] # corpse prototype
    end
    # generate a new item based off of the corpse prototype.

    o = @@corpse_proto.instance # new corpse
    if ('A'..'Z') === short_desc[0]
      o.name = o.name % self.short_desc
    else
      o.name = o.name % self.short_desc.en.a
    end

    in_room.accept(o) # put the object in the same room.
  end

  def channel_flags
    {}
  end
end


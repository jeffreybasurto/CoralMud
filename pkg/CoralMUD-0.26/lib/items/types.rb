
# items and all their types.
$item_types = {:consumables=>[:food], 
               :equipment=>[:armor], # things that should be wearable.
               :trash=>[:trash], # things not really gameplay centric.  Trash items is an example.
               :weapons=>[:weapon],
               :containers=>[:container]}

def item_attribute type
  found = case type
    when :food then ConsumableType.new
    when :armor then EquipmentType.new
    when :trash then TrashType.new
    when :container then ContainerType.new
    when :weapon then WeaponType.new
  end
  found.type = type
  return found
end

class Item
  # returns the type data for a specific type or nil if it doesn't exist.
  def has_type? type
    found = @type_attributes.select {|att| att.type == type }
    if found.empty? then false else found end
  end

  # returns everywhere this item can be worn.
  def worn_locs
    arr = @type_attributes.select {|att| att.is_a?(EquipmentType) }
    locs = []
    arr.each do |att|
      locs += att.worn.keys
    end 
    return locs.uniq
  end
end

# shared interface.
module ItemType
  attr_accessor :type
  def to_s
    "%11s" % type.to_s
  end
end

class ConsumableType
  include ItemType
  define_editor :food_editor 
  define_editor_field({:name=>"charges", :arg_type=>:arg_int, :filter=>:filt_none})
  def initialize
    @charges = 1
  end
  def to_s
    "#{super}:        Charges: #{@charges}"  
  end
end

class EquipmentType
  attr_reader :worn
  include ItemType

  define_editor :armor_editor
  define_editor_field({:name=>"worn", :filter=>:filt_to_flag, :filter_key=>$locs_to_look_at.keys, :type=>:flags})


end

class TrashType
  include ItemType
  define_editor :trash_editor
end

class WeaponType
  include ItemType
  define_editor :weapon_editor

  define_editor_field({:name=>"min", :arg_type=>:arg_int, :filter=>:filt_none})
  define_editor_field({:name=>"max", :arg_type=>:arg_int, :filter=>:filt_none})
  define_editor_field({:name=>"bonus", :arg_type=>:arg_int, :filter=>:filt_none})

  def initialize
    @min = 1
    @max = 1
    @bonus = 1
  end
  def to_s
    "#{super}:         Damage: #{@min}-#{@max}+#{@bonus}"   
  end
end

class ContainerType
  include ItemType 
  define_editor :container_editor
  define_editor_field({:name=>"max", :arg_type=>:arg_int, :filter=>:filt_none})
  def initialize
    @max = 0
  end

  def to_s
    "#{super}:         Max: #{@max}"
  end
end


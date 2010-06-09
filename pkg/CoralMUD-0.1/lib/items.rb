class Item
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # vtags and indexing
  include Resets
  include IDN

  attr_reader :name, :flags

  def to_configure_properties
    ['@name', '@vtag','@id', '@type_attributes', '@flags', '@_reset_list']
  end

  def to_s
    mxptag("send 'edit #{Tag.full_tag(self)}'") + "[Item #{@vtag}]" + mxptag("/send")
  end

  def initialize
    @name = DEFAULT_STRING 
    @type_attributes = []
  end

  #returns an array of types this item currently is.
  def types
    @type_attributes.collect { |att|  att.type }
  end

  # to create an instance this is called every time.
  # note: it's not an instance of the class. It's an instance of the template with a facade.
  # So it's an instance of an instance.
  def instance
    obj = ItemFacade.new(self, true)   
    obj.copy_resets(reset_list)
    obj.reset
    return obj
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

    # transform the tag using the namespace
    vtag = map['@vtag']
    if vtag
      assign_tag vtag, map['@namespace']
      vtag = @vtag
      map['@vtag'] = vtag
    end
    return map
  end
end

class ItemFacade < Facade
  attr_facade :name
  attr_accessor :worn_on

  include CoralMUD::FileIO 
  include CoralMUD::HasStuff
  include Resets

  def to_configure_properties
    ["@id", "@hides", "@name", "@stuff"]
  end

  def initialize thing, assign_id=false
    super thing, assign_id
  end 

  def to_s
    self.short_desc
  end

  def short_desc
    self.name
  end

  def peek anything
    ""
  end

  def view anyone

  end

  def data_transform_on_load v, map
    #hides needs to be looked up.
    hides = map['@hides']
    t = Tag.find_any_obj(map['@hides'])
    if !t || hides == "" || hides == nil
      map['@hides'] = Tag.find_any_obj("do.not.change::paper.doll")[0]
    else
      map['@hides'] = t[0]
    end
    if map['@name'] != "" && map['@name'] != nil && map['@name'] != map['@hides'].name
      self.name = map['@name'] 
    end
    map.delete '@name' # don't set the name at all after this

    # transform each item facade.
    arr = map['@stuff']
    arr.each do |i|
      item = ItemFacade.new(nil, false)
      item.configure(i) # loads each room file.
      accept(item)
    end
    map.delete '@stuff'

    return map
  end

  def data_transform_on_save map
    #id is fine as it is
    # hides should be saved simply as the Tag.full_tag
    map['@hides'] = Tag.full_tag(@hides) 
    # name is only saved if it exists.  Otherwise purge the entire definition.
    map.delete "@name" if @name==nil || @name == '' || @name == @hides.name

    # stuff needs to be get_configure
    stuff = []
    each_stuff do |item|
      stuff << item.gen_configure
    end
    if stuff.empty?
      map.delete '@stuff'
    else
      map['@stuff'] = stuff
    end
    return map
  end


end





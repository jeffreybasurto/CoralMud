class Item
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # vtags and indexing

  attr_reader :name, :type, :flags

  def initialize
    @name = DEFAULT_STRING
    @type = :trash      
  end

  # to create an instance this is called every time.
  # note: it's not an instance of the class. It's an instance of the template with a facade.
  # So it's an instance of an instance.
  def instance
    obj = ItemFacade.new(self)   
    
  end
end


class ItemFacade < Facade
  attr_facade :name
  def initialize thing
    super thing
  end
end


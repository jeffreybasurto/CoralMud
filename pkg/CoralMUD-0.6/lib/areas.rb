# a zone is a namespace for rooms and information a specific area.
class Zone
  attr_accessor :name
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # virtual tag system included.

  def initialize
    @name = "Default Area Name"
  end

  def to_configure_properties
    ['@name', '@vtag']
  end

  def to_s
    "Zone) [#{@vtag}] #{@name}"
  end

  def self.load_zones
    rfiles = File.join("data/areas", "*.yml")
    log :info, "Loading all zones."
    Dir.glob(rfiles).each do |a_file|
      z = Zone.new()
      z.load_from_file(a_file) # loads each room file.
      z.vtag.reassociate(z) # Must be done because initializer is not called for the vtag object.
      log :debug, "Loading zone: #{z.vtag.to_s}"
    end
  end

  def save_zone
    save_to_file "data/areas/%s.yml" % @vtag.to_s
  end
end



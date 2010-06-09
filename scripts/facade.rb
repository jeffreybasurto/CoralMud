require 'benchmark'
class Room
  attr_accessor :name, :sector, :lots, :of, :other, :data
  @@default = {}
  def initialize n, s
    @name, @sector = n, s
    @@default[s] = self if @@default[s] == nil   # If no defaults for this sector yet this is it.
  end

  # lookup a default template based on sector
  def self.[] sect
    @@default[sect]
  end
end
Room.new("In the Ocean", :sector_ocean)
Room.new("Through the Woods", :sector_forest)
Room.new("On the Plains", :sector_plains)

class Facade
  def initialize sect
    @hides = sect 
  end
  # any requests to facade go here and is dispatched to the class hiding behind it.
  def method_missing sym, *args
    # Do we have an alternative default tile?
    Room[@hides].send(sym, *args) 
  end
end
rand_arr = [:sector_ocean, :sector_forest, :sector_plains] * 1000000 # 3 million items.
arr = [] # So arr can shadow this definition.
Benchmark.bmbm do |roar|
  roar.report("Loading 2,500,000 locations.") do
    2500000.times { arr << Facade.new(rand_arr.pop()) }
  end
end



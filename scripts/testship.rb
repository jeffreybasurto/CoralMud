class Part
  attr_accessor :name
  def initialize n 
    @name = n
  end
end  

class Turret < Part
  def initialize 
    super("A Turret")   # call Part#initialize
  end
end

class Cockpit < Part
  def initialize
    super("A Cockpit")   # call Part#initialize
  end
end


class Ship
  def initialize
    @parts = []   # A new list
  end
 
  def add p
    @parts << p  # adds p to parts list 
  end

  # sound off on all the parts by name
  def madeOf
    @parts.each do |p|   # for each part represented by p
      puts p.name        # print it's name to standard output
    end
  end   
end

# Start of our actual program
s = Ship.new
s.add(Turret.new)
s.add(Cockpit.new)
s.madeOf()

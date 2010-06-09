
module Vampiric
end
module Cold
end

class Afflicts
  def initialize modules=[]
    @extended_by = []
   
    # extend based on each affliction in the initializer
    modules.each do each_aff 
      extend(each_aff)
    end
  end
 
  # add a single affliction 
  def add aff_module
    extend(aff_module)
    @extended_by << aff_module
  end

  # remove a single affliction
  def remove aff_module
    @extended_by.delete(aff_module)
    # reconstruct afflictions based on the current modules.
    self = Afflicts.new(@extended_by)
  end
end

class Creature
  def initialize
    @has_these = Afflicts.new
  end
end




c = Creature.new
c = Creature.new

c.afflictions.add(Vampiric)
c.afflictions.remove(Vampiric)


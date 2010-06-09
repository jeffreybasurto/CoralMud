$spell_list = []

class Spell
  attr_accessor :name, :method, :type
  def initialize(name, method, type=:normal)
    @name = name
    @method = method 
    @type= type
    $spell_list << self
  end

  def self.lookup(name)
    $spell_list.each do |sp|
      return sp if sp.name == name
    end    
  end
end

Spell.new("magic missile", :spell_magic_missile, :type_arcane) 
Spell.new("fireball",      :spell_fireball,      :type_fire)

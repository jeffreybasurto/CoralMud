### table of types and their properties.
$dam_type_table = {
                   :type_normal=>[],
                   :type_fire=>[],
                   :type_wind=>[],
                   :type_ice=>[],
                   :type_nature=>[]
                  }



class DamageLog ### For internal use
  def initialize
    @taken_list = []
    @total_health = 0
    @total_damage = 0
    @changed = false
    
  end
  ### this needs to be called any time the maximum health is changed.
  def register_health hp
    @total_health = hp    
  end

  ### heal amt of damage from type, if type exits, only from aggressor, if aggressor exists.
  def heal_damage amt, type, aggressor=nil
    return if amt <= 0

    @changed = true
    @taken_list.each do |d|
      if d.amt >= amt
        d.amt -= amt
        break
      else
        amt -= d.amt
        d.amt = 0
      end
    end
  end

  ### Function to add some damage.
  def add_damage amt, type, aggressor=nil
    @taken_list << Damage.new(amt, type, aggressor)
    @changed = true 
  end

  ### how much hp is left?
  def how_much_left?
    recalc if @changed

    return @total_health - @total_damage
  end

  ### returns a total amount of damage taken
  ### array of types should be passed
  def how_much_taken?
    recalc if @changed
    @total_damage 
  end

  def recalc
    @changed = false
    @total_damage = 0
    @taken_list.each do |d|
      @taken_list.delete d if d.amt <= 0
      @total_damage += d.amt
    end
    @total_damage
  end
end

### Class for damage to be applied to an object/player/ect
class Damage
  attr_accessor :amt
  ### Sets an amount, type, and aggressor responsible. 
  def initialize amt, type, aggressor=nil
    @amt = amt                          ### how much damage
    @type = type                        ### Type of damage dealt.
    @dealt_by = WeakRef.new(aggressor) if aggressor != nil  ### dumps a weak reference to aggressor.
  end

end

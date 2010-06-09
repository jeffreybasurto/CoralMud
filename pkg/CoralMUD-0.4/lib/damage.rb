

$damage_adjectives = %w[pathetic piteous feeble listless weak poor trivial mediocre vigorous forceful potent strong powerful
                        vicious punishing terrific ferocious massive mighty brutal horrific savage crippling]
$damage_adj_interpolate_hash = {1=>0,2=>0,3=>1,4=>1, 5=>2, 6=>2, 10=>4, 30=>8, 100=>$damage_adjectives.count}
$damage_verbs ={:not_plural=> %w[miss tickle scratch nick] + ["lightly graze"] + %w[graze irritate bruise hit wound
                   smite maim mutilate mangle dismember ravage pulverize disfigure
                  destroy eviscerate slaughter annihilate decimate] + ["horribly disfigure"] + %w[OBLITERATE]}
$damage_verbs[:plural] = $damage_verbs.collect {|dv| dv.en.plural}

# return a verb based on a given percent.
def get_verb_from_percent pcnt, plural=:not_plural
  return $damage_verbs[plural].fetch(pcnt) {|i| i>0 ? "OBLITERATE" : "heal" }
end

def get_adjective_from_damage dmg
  puts dmg
  val = interpolate($damage_adj_interpolate_hash, dmg)
  return $damage_adjectives.fetch(val) {|i| i>0 ? "devastating" : "restorative" }
end
module HealthPool
  def dead?
    health <= 0
  end

  def health 
    100 - damage    
  end

  # deals damage and prints the facts about it.
  # returns true if player dies from the hit and false otherwise.
  # however, returns nil if target is already dead.
  def take_damage amt, who=nil
    pcnt = amt * 100 / self.health

    # already dead
    return nil if self.dead?    

    verb = get_verb_from_percent(pcnt)
    verb_plural = get_verb_from_percent(pcnt,:plural)
    adjective = get_adjective_from_damage(amt)
    if who    
      self.view "#{peek(who)} #{verb_plural} you with a #{adjective} attack." + ENDL
      who.view "You #{verb} #{peek(self)} with your #{adjective} attack." + ENDL
      self.in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], who, [self, who],
            "<%=other.peek(actor)%> #{verb_plural} <%=other.peek(arg[0])%> with his #{adjective} attack.", self)
    end
    @damage = [] if !@damage
    @damage << {:amt=>amt, :type=>:normal}

    # if we're dead at this point we should act on it.
    if self.dead?
      self.view "The last bit of life flows from your body.  You've died." + ENDL
      self.in_room.display([:visual, "other.can_see?(actor)"], self, [self], "<%=other.peek(actor).capitalize%> has died.")
      if is_npc?
        self.make_corpse
        self.remove_from_gamespace # remove it from the room and (hopefully) from the gamespace for collection.
      end
      return true
    end
    return false
  end

  def heal_damage amt
    return if !@damage
    
    @damage.each do |dmg|
      if dmg[:amt] > amt
        dmg[:amt] -= amt
        amt = 0
        break
      else
        amt -= dmg[:amt]
        dmg[:amt] = 0
      end
    end

    @damage.delete_if {|dmg| dmg[:amt] <= 0}
    @damage = nil if @damage.empty?
    return amt
  end

  # return how much damage has been taken
  def damage
    count = 0
    @damage.each do |dmg|
      count += dmg[:amt]
    end
    return count
  end
end

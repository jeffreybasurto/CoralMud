### this is the base for all triggers
class TriggerBase
  attr_accessor :fun, :type, :dies, :arg, :owner
  @@trig_list = [] #list for all triggers
  def initialize(owner, type, function, args, dies=true)
    @fun = function
    @type = type
    @dies = dies
    @arg = args
    @owner = Weakref.new(o)
    @@trig_list << self
  end
  # fires this trigger.
  def fire obj
    #executes our method with the given argument.
    return false if obj != owner
    ObjectSpace.garbage_collect
    @owner = nil if !@owner.weakref_alive?
    if @owner != nil
      @owner.send(fun, *arg)
    else
      return true
    end
    return self.dies
  end
  def delete
    @@trig_list.delete self
  end
end

###triggers on entry
class TrigEnter < TriggerBase
  attr_accessor :vnum_list
  def initialize(o, v, f, arg, dies=true)
    super(o, :trig_enter, f, arg, dies)    
    @vnum_list = v
  end
  # test all these trigger and see if one fires with vnum.
  def TrigEnter.poll obj, needle
    @@trig_list.each do |t|
      if t.type == :trig_enter
        t.vnum_list.each do |v| 
          next if v != needle
          t.delete if t.fire(obj)
        end
      end
    end
  end
end

### trigger will fire when you come in proximity
class TrigProx < TriggerBase
  attr_accessor :room_vnum, :xy, :distance

  def initialize(o, v, f, arg, dies=false)
    super(o, :trig_prox, f, arg, dies)
    @xy, @room_vnum, @distance = v[0], v[1], v[2]
  end

  def TrigProx.poll obj, coord, roomnum 
    @@trig_list.each do |t|
      if t.type == :trig_prox
        next if t.room_vnum != roomnum or dist_form(coord, t.xy) > t.distance
        # we can fire.
        t.delete if t.fire(obj)
      end
    end
  end
end

$exit_fix_list = []

### This function is called by the eventmachine in ./core/coral.rb
### It's called hovering around 10 times a second.
### This is not a place for low level timer implementation. EventMachine implements that for us.
def heartbeat 
  $dsock_list.each do |d|
    if d.bust_prompt == true
      if $last_sent != '>'
        d.text_to_socket "#{Time.now.strftime("#R[%I:%M%p]#w")}>" + ENDL
      end
      d.bust_prompt = false
    end
  end
end

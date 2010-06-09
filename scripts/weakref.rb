require 'weakref'
class Player
  def initialize
    @follow = nil
  end
  def follower=(f)
    @follow = WeakRef.new(f)
  end

  def follower
    if @follow.weakref_alive?
      @follower
    else
      false
    end
  end
end



p = Player.new
p2 = Player.new

p.follower = p2

p2 = nil
ObjectSpace.garbage_collect

puts p.follower

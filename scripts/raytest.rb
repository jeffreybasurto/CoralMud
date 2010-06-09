
class Tile
  attr_accessor :wall
  def initialize choice
    if choice == "wall"
      @wall = true    
    end 
    
    if choice == "room"
      @wall = false
    end
  end
end

w = Tile.new("wall")
r = Tile.new("room")

world = [[w, w, w, w, w],
         [w, r, r, r, w],
         [w, r, r, r, w],
         [w, r, r, r, w],
         [w, r, r, r, w],
         [w, w, w, w, w]]



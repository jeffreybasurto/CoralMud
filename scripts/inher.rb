
class BaseRoom 
  attr_accessor :people, :vnum
  def initialize
    @people = []
    @vnum = 0
  end
  
  def player_to_room name
    people << name
  end
  def player_from_room name
    people[name].delete
  end
end

class CityRoom < BaseRoom
  attr_accessor :name
  def initialize
    super
    @name = 0
  end
end


r = CityRoom.new



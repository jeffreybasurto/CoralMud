module Test
  @@test = "Roar"
end

class Meh
  include Test
  @test = "Roar"

  def self.roar
    puts @test
  end
  def roar
    puts @@test
  end
end

m = Meh.new
m.roar
Meh.roar

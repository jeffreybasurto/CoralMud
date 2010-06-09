
class Roar
  @@test = []
  def mew 
    @@test << 1
  end
  def test
    @@test
  end
end

r = Roar.new
r.mew

m = Roar.new
m.mew

p r.test


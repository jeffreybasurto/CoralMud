
class Roar
  @@common_var = "lion"
  def common_var
    @@common_var
  end
end

class Mew
  @@common_var = "kitty"
  def common_var
    @@common_var
  end
end

cat = Mew.new
bigcat = Roar.new

p cat.common_var
p bigcat.common_var

##somewhere else in the program.
@@common_var = "gorilla"


p cat.common_var
p bigcat.common_var


class Class

  def attr_test
    class_variable_set(:@@test, 10)
  end

  def attr_test2 val
    p class_variable_get(:@@test)
  end
end

class Roar
  attr_test
  attr_test2 10
  def getem
    @@test
  end
end

r = Roar.new

p r.getem

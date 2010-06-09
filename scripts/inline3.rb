require 'inline'
require 'ruby_to_ansi_c'
class MyTest

  def factorial(n)
    f = 1
    n.downto(2) { |x| f *= x }
    f
  end

  inline(:Ruby) do |builder|
    builder.optimize :factorial
  end
end

m = MyTest.new

m.factorial(100)

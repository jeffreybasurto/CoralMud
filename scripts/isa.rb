class Meh
  def initialize
    if Meh.class_variable_defined?(:@@a)
      puts "Defined!"
    else
      puts "Not defined!"
    end
  end
end

Meh.new

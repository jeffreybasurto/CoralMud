require 'yaml'

class Roar
  attr_accessor :roar

end

class Test
  attr_accessor :roar
  def initialize
    @roar = Roar.new
  end
  def to_yaml_properties
    ['@roar']
  end
end

t = Test.new



=begin File.open("yamltest.yml", "w") do |f|
  YAML::dump t,f
end

ytest = YAML::load_file "yamltest.yml"

p ytest.roar
=end 

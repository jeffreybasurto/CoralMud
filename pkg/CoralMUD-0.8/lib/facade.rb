# used to build facades of another class.   Particularly useful for saving memory on instances of template objects...like items or mobiles.
class Class
  def attr_facade (*attributes)
    attributes.each do |att|
      # for each var
      define_method("#{att}=") do |val|
        self.class.send(:define_method, "#{att}") do 
          instance_variable_get("@#{att}")
        end
        instance_variable_set("@#{att}",val)
      end
    end
  end
end

class Facade
  def initialize thing
    @hides = thing # thing hides behind facade
  end
  def method_missing name, *args
    @hides.send(name, *args)
  end

  def to_s
    "#{@hides}"
  end

  def is_a? type
    return @hides.is_a? type
  end

end



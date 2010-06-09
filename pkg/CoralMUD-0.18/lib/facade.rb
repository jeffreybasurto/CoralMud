module IDN
  @idnum = nil
  @idnum_hash = {}
  class << self
    attr_accessor :idnum
    def lookup number
      @idnum_hash[number]
    end

    # catelogy an object by the idnumber
    def catelog obj
      @idnum_hash[obj.id] = obj
    end

    def idnum_hash
      @idnum_hash
    end
  end
  attr_accessor :id
  def gen_idn
    if !IDN.idnum
      File.open('data/idnum.txt', 'r') do |fin|
        IDN.idnum = YAML::load(fin)
      end
    end
    IDN.idnum += 1
    File.open('data/idnum.txt', 'w' ) do |out|
      YAML::dump IDN.idnum, out
    end
    
    @id = IDN.idnum
    IDN.catelog(self)
  end
  def register_idn
    IDN.catelog(self) if @id
  end
end

# used to build facades of another class.   Particularly useful for saving memory on instances of template objects...like items or mobiles.
class Class
  def attr_facade (*attributes)
    attributes.each do |att|
      # for each var
      define_method("#{att}=") do |val|
        return if !val
        self.metaclass.send(:define_method, "#{att}") do 
          instance_variable_get("@#{att}")
        end
        instant
e_variable_set("@#{att}",val)
      end
    end
  end
end

class Facade
  include IDN
  def initialize thing, assign_id=true
    gen_idn if assign_id
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

  # returns true or false 
  # True if thing is hiding behind this facade.
  def instanced_from? thing
    @hides == thing
  end

  def ===(other)
    return @hides.is_a? other
  end
end


# simple proxy.  Mirror everything.
class Proxy
  # remove every method except key internally used ones.
  instance_methods.each { |m| undef_method m unless m =~ /^__.*__$/ }

  def initialize something
    @target = something
  end

  def method_missing(name, *args, &block)
    @target.__send__(name, *args, &block)
  end
end

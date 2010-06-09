class Machine
  def initialize first_state
    @state = first_state
    @state_dictionary = {}
  end
  def run seed
    while (parsed_value = @parser.call(seed))
      @state = @state_dictionary[@state].call(parsed_value)
    end
  end
  def parser &blk
    @parser = blk
  end
  def create state, &blk
    @state_dictionary[state] = blk
  end  
end

# create a state machine with an initial state specified.
m = Machine.new :one

# how do we parse the seed?
m.parser do |obj|
  obj.slice!(/[a-zA-Z]+/)
end

# define the states, each state should return the next.
m.create :one do |word|
  puts "First word = #{word}"
  :two
end

m.create :two do |word|
  puts "Second word = #{word}"
  :one
end


m.run [:penny, :penny, :penny]
m.resolve


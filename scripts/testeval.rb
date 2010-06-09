require 'thread'

class ScriptEnvironment
  attr_accessor :messages
  def initialize str
    @name, @messages = str, Queue.new
  end
  def run txt, b=self.binding
    @script = Thread.new {
      def message_loop
        loop do
          msg = @messages.pop
          yield msg
        end
      end
      test_var = "roar" 
      $SAFE = 2
      b.eval(txt)
    }
  end
end
laughing_man = ScriptEnvironment.new "A test script"

str = <<END
puts self
puts test_var
#message_loop do |msg|
#  puts msg
#  if msg == :exit
#    break
#  end
#end
END

class Object
  def get_bind
    return binding
  end
end

o = Object.new

t = laughing_man.run str, o.get_bind

laughing_man.messages.push "Roar!"
laughing_man.messages.push :exit
t.join # wait for t to finish.


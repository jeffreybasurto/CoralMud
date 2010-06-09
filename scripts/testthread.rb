
require 'thread'

t = Thread.new do 
  loop do
    s = gets
    s.strip!
    puts s
  end
end



loop do
  puts "OWNED"
  sleep 1
end


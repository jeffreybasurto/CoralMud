require 'thread'

a= Thread.new do
  loop do
    sleep 1
    puts "Roar!"
  end
end

b = Thread.new do
  loop do
  end
end
b.join

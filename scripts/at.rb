require 'benchmark'
class Room
  @@name = "Meh"
  def name; @@name; end
end

MAX_X = 10000
MAX_Y = 10000

a = [[Room.new] * MAX_X] * MAX_Y # populate array.

Benchmark.bm do |roar|
  roar.report("C Style") {
    x = 0
    y = 0
    while x < MAX_X
      while y < MAX_Y
        a[x][y].name # Do nothing with it
        y += 1
      end
      x += 1
      y = 0
    end
  }

  roar.report("Using closure") {
    a[0...MAX_Y].each do |y|
      y[0..MAX_X].each do |node|
        node.name
      end   
    end
  }
end


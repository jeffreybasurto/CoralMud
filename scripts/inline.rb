
require "inline"
class MyTest
  inline do |builder|
    builder.c "
      int dist_form(int x1, int y1, int x2, int y2) {
        return sqrt( (double)((x2 - x1) * (x2 - x1)  +  (y2 - y1) * (y2 - y1)) );
      }
    ";
  end
end

t = MyTest.new

hyp = t.dist_form(0, 0,  10, 10)
adj = 10 - 0

puts Math::acos(adj/hyp)

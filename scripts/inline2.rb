require "inline"
class MyTest
  inline do |builder|
    builder.c "
      /* right number of calls anyways */
      int trigcalls(double d1) {
        return sin(atan(d1/10)) + cos(atan(d1/10));
      }"
  end
end

t = MyTest.new

100000.times do |i|
   t.trigcalls(i)
end


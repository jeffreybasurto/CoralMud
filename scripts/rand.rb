### Decided to give array an extension so you can do [1,2,3].rand to grab a random element of an array.
class Array
  def rand
    self[Kernel.rand(self.length)]
  end
end

### make o_rand an alias of our original rand
alias o_rand rand

### redefine rand to make a call to o_rand with a wrapper.
def rand a1=nil, a2=nil
  if !a1.kind_of?(Enumerable) and a2 == nil
    o_rand(a1)
  elsif a1.kind_of?(Enumerable)
    as_array = a1.to_a
    as_array[o_rand(as_array.length)]
  elsif a1 != nil
    a1 + o_rand(a2)
  end
end


1000.times do
  rand 1..100 
end

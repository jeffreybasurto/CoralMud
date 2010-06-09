
### extend center function for strings.
class String
  ### redefine center to o_center
  alias o_center center

  def bust_color code='#' ### Change this to your code or pass it in bust_color
    gsub! Regexp.new("#{code}[^0-9^#{code}^ ]"), ""
  end  

  def center count, fill=' '
    s = self.dup ### dup self
    s.bust_color 
    s.o_center(count, fill).sub(s, self)
  end
end

teststr = "jfwof #r#r#rtest #y#y#ystring"

puts teststr.center 20, '_'
1000.times do 
  teststr.center 20, '_'
end


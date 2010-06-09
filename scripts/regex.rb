s = "&"
s2 = Regexp.new(s)

1000.times do 
  s =~ s2
end

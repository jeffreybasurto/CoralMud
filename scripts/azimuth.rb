def dist_form(a1, a2)
  Math.sqrt( (a2[0] - a1[0])**2 + (a2[1] - a1[1])**2)
end

def get_azi a, b
  # find the distance between the two points.
  hyp = dist_form a, b

  adj = (b[1] - a[1])

  #which hemisphere?
  if (b[0] - a[0]) >= 0
    d = 0
  else
    adj = -adj
    d = 180
  end

  # cos^-1 (adj/hyp) * 180/PI  
  r = Math::acos(adj/hyp) # answer in radians
  d = r * 180 / Math::PI + d 
end

print "Should be 0 degrees: #{get_azi([0,0], [0,1])}\n"

print "         90 degrees: #{get_azi([0,0], [1,0])}\n"

print "        180 degrees: #{get_azi([0,0], [0,-1])}\n"
print "        270 degrees: #{get_azi([0,0], [-1,0])}\n"
print "    ------      ------       ------\n"
print "         45 degrees: #{get_azi([0,0], [1,1])}\n"
print "        135 degrees: #{get_azi([0,0], [1,-1])}\n"
print "        225 degrees: #{get_azi([0,0], [-1,-1])}\n"
print "                   : #{get_azi([0,0], [-3,2])}\n"
print "        315 degrees: #{get_azi([0,0], [-1, 1])}\n"



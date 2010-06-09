# Linear interpolation. Takes two known data points, say (xa,ya) and (xb,yb),
# and the interpolant is given by:
#
#      y = ya + ((x - xa) * (yb - ya) / (xb - xa)) at the point (x,y)
#
# Arguments are:
#
#    ** known_data_points is a hash of key => value pairs where key is
#       the "x" values and value is the "y" values. Example hash:
#         {  0 => 10,
#           10 => 90,
#           95 => 280,
#          100 => 300 }
#
#    ** x is the known point somewhere in the range of "x" values
#
# Solves for y, a point somewhere in the range of supplied y values which
# is relative to the position of the x point in the supplied x values.
#
# Example results of calling the function with the above example hash
# and these known x values:
#     x = 5    => 50
#     x = 10   => 90
#     x = 50   => 179
#
# Thusly, you can supply as FEW or as MANY known data points as is needed to approximate
# any imaginable curve fitting equation. Simply keep in mind that linear interpolation is
# being performed between the two closest known points. You may only need 4 or 5 known data
# points to represent a gentle sloping curve WHEREAS you may need 15 or more known points
# to approximate a more aggressive curve shape.
#
def interpolate(known_data_points, x)
  xmin, xmax = nil, nil
 
  keys = known_data_points.keys.sort


  # find the first known x value at or below the provided x value…
  keys.reverse_each do |k|
    if k <= x
      xmin = k
      break
    end
  end
  xmin = keys[-1] if xmin == nil

  # find the first known x value at or above the provided x value…
  keys.each do |k|
    if k >= x
      xmax = k
      break
    end
  end
  xmax = keys[0] if xmax == nil
  # if supplied argument "x" is outside the range of known "x" values, bail out now!
#  raise InterpolationError if x > xmax || x < xmin
  # if supplied argument "x" falls exactly on a known x data point, simply return
  # the relative y value now!
  return known_data_points[x] if known_data_points[x] != nil
  # prevent divide by zero errors…
  if (xmax - xmin) == 0
#    raise InterpolationError
  end

  # finally, interpolate and return the answer!
  return known_data_points[xmin] + (((x - xmin) * (known_data_points[xmax] - known_data_points[xmin])) / (xmax - xmin))
end

puts f=interpolate({1=>1, 2=>1, 3=>2, 4=>2, 5=>3, 25=>25, 100=>100 }, 50)


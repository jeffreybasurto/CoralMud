
arr = Array.new(20, "1234567890123456789012345678901234567890")

1000.times do
  narr = Array.new(20)
  20.times do |z|
    narr[z] = arr.slice(0..40) ## Slice all of it for now
  end
end


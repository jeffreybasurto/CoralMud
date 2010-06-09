#!/usr/bin/env ruby

print "Enter your name: "
name = gets.chomp
puts "Hello #{name}"

print "Enter your some more names separated by commas: "
while true
  name = gets(',').chomp(',')
  puts "Hello #{name}"
end

require 'benchmark'

$color_table = {
    "#z" => "\e[2;30m",
    "#Z" => "\e[1;30m",
    "#r" => "\e[2;31m",
    "#R" => "\e[1;31m",
    "#g" => "\e[2;32m",
    "#G" => "\e[1;32m",
    "#y" => "\e[2;33m",
    "#Y" => "\e[1;33m",
    "#b" => "\e[2;34m",
    "#B" => "\e[1;34m",
    "#m" => "\e[2;35m",
    "#M" => "\e[1;35m",
    "#c" => "\e[2;36m",
    "#C" => "\e[1;36m",
    "#w" => "\e[2;37m",
    "#W" => "\e[1;37m",
    "#n" => "\e[0m",
  }

$comp_tab = Regexp.union *$color_table.keys

def parse_color(data)
  data.gsub($comp_tab) do |s|
    $color_table[s]
  end
end

line = "#rH#re#Rll#go#n#rT#rh#Re#n"

puts parse_color line

Benchmark.bmbm do |x|
  x.report("parse_color") { 
    1000.times do; parse_color(line); end 
  }
end
 

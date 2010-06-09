require 'linguistics'
require 'benchmark'
Linguistics::use( :en ) # extends Array, String, and Numeric


Benchmark.bmbm do |r|
  r.report("test") do
    5000.times do 
      "unicycle".en.a
    end
  end
end

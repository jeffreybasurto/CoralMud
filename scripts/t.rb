require 'benchmark'

Benchmark.bm do |b|
  b.report("When raised: ") do
    10000.times do
      Integer("LAWL") rescue nil
    end
  end

  b.report("No raise: ") do
    10000.times do
      begin
        Integer("100")
      rescue
        next
      end
    end
  end
end


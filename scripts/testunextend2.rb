require 'un'

module One;  def roar; p "Roar!"; end; end
class Two; end

c = Two.new.extend(One).roar
c.unextend(One)

begin
  c.roar
rescue
  p "Fail."
end

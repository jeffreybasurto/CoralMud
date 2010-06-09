require 'inline'
 
class Object
  inline(:C) do |builder|
    builder.c <<-EOC
      void unextend(VALUE module) {
        VALUE klass = rb_singleton_class(self);
        VALUE prev_klass = Qnil;
        while (klass) {
          if (klass == module || RCLASS(klass)->m_tbl == RCLASS(module)->m_tbl) {
            RCLASS(prev_klass)->super = RCLASS(klass)->super;
            rb_clear_cache();
            return;
          }
          prev_klass = klass;
          klass = RCLASS(klass)->super;
        }
      }
    EOC
  end
end
 
module Vampiric
  def bite
    puts "chomp"
  end
end
 
class Creature
end
 
a = Creature.new
begin
  a.bite
rescue
  puts "no bite"
end
a.extend Vampiric
a.bite
a.unextend Vampiric
begin
  a.bite
rescue
  puts "no bite"
end
 

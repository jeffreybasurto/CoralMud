class Reset
  define_editor :reset_editor
  define_editor_field({:name=>"target", :filter=>:filt_from_vtag, :opts=>{:view_filter=>proc do|idn| IDN.lookup(idn) end}})
  define_editor_field({:name=>"max", :arg_type=>:arg_int})
  define_editor_field({:name=>"now", :arg_type=>:arg_int})
  define_editor_field({:name=>"chance", :arg_type=>:arg_int})

  attr_accessor :target

  def to_yaml_properties
    ['@target', '@max', '@now', '@chance']
  end

  # Reset.new(number)
  def initialize number
    assert { number.is_a?(Integer) }
    @target = number # target is equal to an idnumber
    @max = 1
    @now = 1
    @chance = 100
  end

  def responsible_for_these
    @responsible_for_these ||= []
  end

  def do_the_reset?
    responsible_for_these.delete_if {|thing| thing.recycled?}
    responsible_for_these.count < @max 
  end

  # dot he reset
  def do_it here
    return if rand((1..100)) > @chance

    thing = IDN.lookup(self.target)
    @now.times do 
      instanced = thing.instance
      @responsible_for_these << instanced # add it to what this reset monitors.
      here.accept(instanced)
    end
  end
end

module Resets
  def reset_list
    @_reset_list ||= [] 
  end  

  # creates a reset command on this object.
  def create_reset idnumber
    begin
      reset_list << Reset.new(idnumber)
    rescue Exception=>e
      log_exception e
    end  
  end

  # reset this thing and call up the chain.
  def reset
    @_reset_list.each do |a_reset|
      next if !a_reset.do_the_reset?
      a_reset.do_it(self)
    end
  end  

  def copy_resets list
    @_reset_list = list.collect {|r| r.dup}
  end
end

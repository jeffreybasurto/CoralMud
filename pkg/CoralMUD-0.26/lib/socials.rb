class Social
  attr_accessor :name, :noarg, :onoarg, :found, :ofound, :tfound, :auto, :oauto
  include CoralMUD::FileIO # standard saving mechanisms.
  include CoralMUD::VirtualTags # virtual tag system included.

  @list = []
  class << Social;  attr_accessor :list; end  

  def to_configure_properties
    ['@vtag', '@name', '@noarg', '@onoarg', '@found', '@ofound', '@tfound', '@auto', '@oauto']
  end

  def initialize
    Social.list << self # add it to the main list of available socials.
    @name = "default"
    @noarg = "You default."
    @onoarg= "$n defaults."
    @found = "You default at $M."
    @ofound= "$n defaults at $N."
    @tfound= "$n defaults at you."
    @auto =  "You default at yourself."
    @oauto = "$n defaults at $mself."
  end

  # execute it based on these given parameters.
  def execute actor, target=[nil]
    def himher thing
      multiple = thing.count > 1      

      if multiple 
        return "them"
      end

      case thing[0]
      when Player then "him"
      when ItemFacade then "it"
      else ""
      end
    end
    room_msg, self_msg, vict_msg = @ofound.dup, @found.dup, @tfound.dup


    if target.include?(actor) # if they're the same person then it's an auto
      target = [actor]
      room_msg = @oauto.dup
      self_msg = @auto.dup
      vict_msg = nil
    elsif target[0] == nil
      room_msg = @onoarg.dup
      self_msg = @noarg.dup
      vict_msg = nil
    end
    room_msg.gsub!("$n", "<%=other.peek(actor)%>")
    room_msg.gsub!("$N", "<%=other.peek(if arg[0].include?(other) then arg[0]-[other]+['You'] else arg[0] end)%>")
    room_msg.gsub!("$m", himher([actor]))
    room_msg.gsub!("$M", himher(target))

    self_msg.gsub!("$M", himher(target))
    self_msg.gsub!("$m", himher([actor]))
    if target
      self_msg.gsub!("$N", actor.peek(target))
    end
    actor.view("#G"+self_msg+"#n" + ENDL)
    
    room_msg.untaint
    if target[0]
      if target.count > 1   
        actor.in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], actor, [actor], "#G"+room_msg+"#n", target)
      else
        actor.in_room.display([:visual, "other.can_see?(actor) || other.can_see?(arg[0])"], actor, [actor, *target], "#G"+room_msg+"#n", target)
        target.each do |one_targ|
          vm = vict_msg.dup
          vm.gsub!("$n", one_targ.peek(actor))
          one_targ.view("#G"+vm+ "#n" + ENDL)
        end
      end
    else
      puts room_msg
      actor.in_room.display([:visual, "other.can_see?(actor)"], actor, [actor], "#G"+room_msg+"#n", "")
    end
  end

  # lookup a specific social based on a str
  def self.lookup str
    things_in_room = {"socials"=>[]}
    things_in_room["socials"] = Social.list

    # parse the string, use a specific list, and it is destructive to the string.
    found = query_parse str, things_in_room, true
  end

  def save_social
    path = "%s.yml" % @vtag.to_s
    save_to_file "data/socials/%s" % path
    return path
  end

  def self.save_all
    arr = [] # list of all file paths
    Social.list.each do |s|
      arr << s.save_social
    end
    File.open('data/socials/social_list.txt', 'w') do |f|
      arr.each {|str| f.puts str }
    end
  end

  def self.load_socials
    f = File.open('data/socials/social_list.txt', 'r')
    arr = f.readlines
    log :info, "Loading all socials."
    arr.each do |a_file|
      a_file = "data/socials/#{a_file.strip}"
      s = Social.new()
      s.load_from_file(a_file) # loads each room file.
      s.reassociate_tag() # Must be done because initializer is not called for the vtag object.
      log :debug, "Loading social: #{s.vtag.to_s}"
    end
  end


  def to_s
    mxptag("send 'edit #{Tag.full_tag(self)}'") + "[Social #{@vtag}]" + mxptag("/send")
  end

end

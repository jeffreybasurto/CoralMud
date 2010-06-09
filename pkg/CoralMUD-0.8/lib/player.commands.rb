
# Generates separators for output to players.
# example is in cmd_commands
def format_generator length=5
  Fiber.new do
    count = 0
    loop do
      count += 1
      if count == length
        count = 0
        Fiber.yield ENDL
      else
        Fiber.yield ""
      end
    end
  end
end


#is instanced off for player command tables.
class CommandTable
  attr_accessor :cmds
  def initialize
    @cmds = []
    init_cmd_table
  end

  # This is the initialize function that must be called manually to grab refernces from the global table.
  def init_cmd_table
    # Right now just adding all commands into the copied table. Maybe later a check for if is immortal or not.
    $tabCmd.each do |c|
      @cmds << c
    end
    $tabWizCmd.each do |c|
      @cmds << c
    end
    return true
  end


  def cmd_lookup com
    @cmds.each do |c|
      if c.must_type_full == true
        return c if com == c.cmd_name
      else
        return c if is_prefix com, c.cmd_name
      end
    end

    ### fail, if we found partial match we should do something about it here later.

    return nil
  end
end

#
# The command table, very simple, but easy to extend.
# This table is the prototype for the global table every 
# character loads with. The reference the elements, not copy.
#
$tabCmd += [
  Command.new("north",    :arg_none),
  Command.new("east",     :arg_none),
  Command.new("south",    :arg_none),
  Command.new("west",     :arg_none),
  Command.new("quit",     :arg_none,  true),
  Command.new("who",      :arg_none),
  Command.new("look",     [[:arg_int!], [:arg_word!], [:arg_none]]),
  Command.new("commands", :arg_none),
  Command.new("help",     [[:arg_word!], [:arg_none]]),
  Command.new("say",      :arg_str),
  Command.new("save",     :arg_none),
  Command.new("track",    :arg_player_in_game!),
  Command.new("open",     :arg_dir),
  Command.new("close",    :arg_dir),
  Command.new("inews",    :arg_str),
  Command.new("iruby",     :arg_str),
  Command.new("ichat",     :arg_str),
  Command.new("icode",     :arg_str),
  Command.new("igame",     :arg_str),
  Command.new("ichannels", :arg_str),
  Command.new("inventory", :arg_none), 
  Command.new("test",     :arg_none),
#imm commands moved to new table.  Most players will not need to access other table.
]

$tabCmd.uniq!

$tabWizCmd += [
  Command.new("goto",  :arg_str),
  Command.new("wizhelp",  :arg_none),
  Command.new("linkdead", :arg_none),
  Command.new("shutdown", :arg_none, true),
  Command.new("buildwalk",  :arg_none),
  Command.new("asave",   :arg_none),
  Command.new("vtag",  :arg_str),
  Command.new("instance",   :arg_str),
  Command.new("create", [[:arg_class!], [:arg_str]]),
  Command.new("edit",   [[:arg_str],[:arg_none]])
]

$tabWizCmd.uniq!

class String
  ### check to see if expected args exist for this string.
  ### expected must be a single dimension array.
  def check_args expected
    s = self.dup
    product = []
    expected.each do |arg_expected|
      if arg_expected == :arg_none and s != ''
        return false
      end
      processed = s.send(arg_expected)
      if processed == nil and arg_expected != :arg_none
        return false ### fail  
      end
      product << processed
    end
    return product
  end
end
class Player
  ### Function to execute a command just as though it were typed.
  ### example:   player.execute("look")
  ###            player.execute("look", "at Retnur");
  def execute_command comm, arg=""
    if @editing.empty? == false
      begin
        while !@editing.empty?
          if !@editing[0].respond_to?(:class_editor)
            text_to_player "#{@editing[0].class} class has no editor defined for it." + ENDL
            @editing.shift
          else
            break
          end
        end
        return if @editing.empty?
        edit_arr = @editing[0].class_editor.find_command(comm)
        if edit_arr[0]
          # act on the command found.  
          new_arg = edit_arr[0].filter(arg, self) # returns what the players arg translates into

          if new_arg == nil || (arg.empty? && edit_arr[0].arg_type != :arg_none)
            text_to_player "Incorrect format." + ENDL
          else
            edit_arr[0].call_fun(self, @editing[0], new_arg)
            execute_command("show") if edit_arr[0].name != "show" && @editing[0]
          end
          return
        end

      rescue Exception=>e
        text_to_player "Editor command failed." + ENDL
        log_exception e
      end
    end

    if (c = self.command_table.cmd_lookup(comm))
      args_to_pass = [c] #First arg is always command table lookup, and once args populate the array we'll splat it.
      failure = true
      ### If it's an array passed it has multiple arguments possibly.
      ### If not it represents a single argument.   These are defined on the table.
      if c.cmd_args.is_a?(Array) == false
        c.cmd_args = [[c.cmd_args]]
      end

      c.cmd_args.each do |each_arr|
      ### okay, since there is arrays involved it will use the full format
      ###  Like [[arg_str], [arg_none]]
      ### for each array contained we must check to see if it's valid from start to end.
      ### If not valid we go to the next.  All arrays must fail for it really to fail the checks.
        processed = arg.check_args each_arr
        if processed == false          
          next
        end
        failure = false ### found a buyer.
        args_to_pass = args_to_pass + processed  ### This is how we're passing it. win
        break
      end
 
      ### if we failed let's report our failure.
      if failure == true
        if c.respond_to? :arg_failure_msg
          # Failure message defined.  Pass to this method which arg failed.
          text_to_player c.arg_failure_msg
        else
          text_to_player "Bad arguments (#{arg}) for #{c.cmd_name} command." + ENDL
        end
        return 
      end
      ### dispatched to cmd_function
      begin
        self.send(c.cmd_funct, *args_to_pass)
      rescue Exception=>e
        log_exception e
        text_to_player "Command failed." + ENDL
      end
    else
      self.text_to_player "No such command." + ENDL
    end
  end

  ### command to start editing something. 
  def cmd_edit comm_tab_entry, arg
    if arg == nil
      thing = [in_room]
    else
      # valid tag
      thing = Tag.find_any_obj(arg)
      if !thing
        text_to_player("Nothing found to edit." + ENDL)
        return
      end
    end

    @editing=@editing || []
    @editing.unshift thing[0]

    found = thing.shift
    text_to_player "#Gfound> #{found}" +ENDL
    thing.each do |element|
      text_to_player "#G#{element}#n" +ENDL
    end
    execute_command("show")
  end

  ### If no argument display all available channels.
  def cmd_ichannels command_table_entry, arg
    buf = "The following commands are available:" + ENDL
    i = 0
    $imc_channel_list.each_pair do |k,v|
      i += 1
      z = "[On]"     
      buf << v[1] + ("[" + i.to_s + "] " + v[0]).ljust(25) + k.to_s.ljust(12) + z + ENDL 
    end
    text_to_player buf
  end

  def cmd_iruby command_table_entry, arg
    $imclock.synchronize do
      $imcclient.channel_send("#{name.capitalize}", "Server02:iruby", arg)
    end
  end

  def cmd_iadmin command_table_entry, arg
    $imclock.synchronize do
      $imcclient.channel_send("#{name.capitalize}", "Server01:admin", arg, "ice-msg-p")
    end
  end

  def cmd_igame command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:icode]) == nil
        text_to_player "You will no longer observe the igame channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:igame] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the igame channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the igame channel." + ENDL
          @channel_flags.delete(:igame)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:igame", arg)
      end
    end
  end


  def cmd_icode command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:icode]) == nil
        text_to_player "You will no longer observe the icode channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:icode] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the icode channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the icode channel." + ENDL
          @channel_flags.delete(:icode)
        end
      end      
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:icode", arg)
      end
    end
  end
  
  def cmd_ichat command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:ichat]) == nil
        text_to_player "You will no longer observe the ichat channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:ichat] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the ichat channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the ichat channel." + ENDL
          @channel_flags.delete(:ichat)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server01:ichat", arg)
      end
    end
  end
  def cmd_inews command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:inews]) == nil
        text_to_player "You will no longer observe the inews channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:inews] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the inews channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the inews channel." + ENDL
          @channel_flags.delete(:inews)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:inews", arg)
      end
    end
  end

  def cmd_sprint command_table_entry, arg
    if flags.include?("sprint")
      flags.delete("sprint")
      text_to_player "Sprint off." + ENDL
    else
      flags << "sprint"
      text_to_player "Sprint enabled." + ENDL
    end 
  end
  def cmd_stop arg
    stop
  end

  def cmd_buildwalk command_table_entry, arg
    # either set build walk or remove it.
    if flags.include?("build walk")
      flags.delete("build walk")
      text_to_player "Build walk disabled." + ENDL
    else
      flags << "build walk"
      text_to_player "Build walk enabled." + ENDL
    end
  end

  def goto_make_room vnum
    if vnum <= 0
      text_to_player "Invalid room. Cannot create." + ENDL
      return
    end

    r = Room.new(vnum)
    text_to_player "Created." + ENDL
    return r
  end

  # target a specific 
  def cmd_target command_table_entry, arg
   
    
  end
  def cmd_goto command_table_entry, arg
    found = Tag.find_any_obj arg, Room
    
    if found == nil
      p = arg.get_player
      if !p
        text_to_player "That isn't a valid rvnum or character name." + ENDL
        return
      end
      room = p.in_room
    else
      room = found[0] # must be of type Room
    end 

    if room == in_room
      text_to_player "You are already there." + ENDL
      return
    end

    if (in_room != nil)
      in_room.text_to_room "#{name} disappears in a cloud of sulfur." + ENDL
      in_room.remove_player(self)
    end
    room.accept_player(self)
    room.text_to_room "#{name} appears in a cloud of sulfur." + ENDL
  end

  def cmd_track command_table_entry, r
    m = Automap.new(r.in_room, [(-5..5), (-2..2)])
    m.view(self)
  end

  def cmd_asave c_t_e, arg
    text_to_player "All areas saved." + ENDL
    Tag.search_class Zone do |z|
      z.save_zone # write this zone to area file.
    end
  end

  def cmd_debug command_table_entry, arg
    damage(1)
    text_to_player "#{health} #{damage}" + ENDL
    heal(1)
    text_to_player "#{health} #{damage}" + ENDL
  end 

  # automatically creates new rooms and digs them out in a direction.
  def buildwalk(dir)
    m = Automap.new(in_room, [(-1..1),(-1..1)], {:full_traverse=>true})
    found = m.find(Automap.offset([0,0], dir))

    if !found
      r = nil 
    else
      r = found[:room]
    end

    if r == nil
      new_room = Room.dig_rooms(in_room.vnum, Vnum.gen_vnum, dir)
      new_room.sector = in_room.sector # same sector as old room
      new_room.namespace = in_room.namespace
      new_room.assign_tag Tag.gen_generic_tag(new_room), in_room.namespace
    else
      Room.dig_rooms(in_room.vnum, r.vnum, dir)
    end
  end
  def cmd_east command_table_entry, arg
    text_to_player "You walk east." + ENDL
    if in_room.exit_list[1] && in_room.exit_list[1].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end
    if !in_room.exit_list[1] 
      if flags.include?("build walk")
        buildwalk(1)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[1].enter(self)
  end

  def cmd_south command_table_entry, arg
    text_to_player "You walk south." + ENDL

    if in_room.exit_list[2] && in_room.exit_list[2].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end

    if !in_room.exit_list[2]
      if flags.include?("build walk")
        buildwalk(2)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[2].enter(self)
  end
  def cmd_west command_table_entry, arg
    text_to_player "You walk west." + ENDL

    if in_room.exit_list[3] && in_room.exit_list[3].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end
    if !in_room.exit_list[3]
      if flags.include?("build walk")
        buildwalk(3)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end 
    in_room.exit_list[3].enter(self)
  end
  def cmd_north command_table_entry, arg
    text_to_player "You walk north." + ENDL
    if in_room.exit_list[0] && in_room.exit_list[0].flags_state.is_set?(:closed)
      text_to_player "The exit is closed." + ENDL
      return
    end

    if !in_room.exit_list[0]
      if flags.include?("build walk")
        buildwalk(0)
      else
        text_to_player "You can't go that direction." + ENDL
        return
      end
    end
    in_room.exit_list[0].enter(self)
  end

  # Look command function
  def cmd_look command_table_entry, arg
    text_to_player mxptag("expire")
    arr = [(-5..5), (-1..1)]

    if arg.is_a?(Integer)
      arr = [(-5-arg/2..5+arg/2), (-1-arg/3..1+arg/3)]
    elsif arg.is_a?(String)
      if !arg.exit_code_to_i
        arr = [(-5..5), (-1..1)]
      else
        i = arg.exit_code_to_i
        arr = case i
          when 0 then [(-5..5), (0..2)]
          when 1 then [(-2..8), (-1..1)]
          when 2 then [(-5..5), (-2..0)]
          when 3 then [(-8..2), (-1..1)]
        end
      end
    end
    m = Automap.new in_room, arr
    m.view(self)

    text_to_player "#nYou see..." + ENDL
    in_room.people.each do |actor|
      next if actor == self
      text_to_player "#{actor.name} is here." + ENDL
    end
    if (!@editing.empty?)
      execute_command("show") # print the editor menu.
    end
  end


  def cmd_shutdown command_table_entry, arg
    text_to_world ("The game is rebooting.  Please come back in a few minutes." + ENDL)
    $shut_down = true
  end

  def cmd_linkdead command_table_entry, arg
    found = false
    $dplayer_list.each do |xPlayer|
      if xPlayer.socket.nil?
        text_to_player "%s is linkdead." % xPlayer.name + ENDL
        found = true
      end
    end
    if !found
      text_to_player "Noone is currently linkdead." + ENDL
    end
  end

  def cmd_help command_table_entry, arg
    if arg == nil
      length = 65
      col = 0
      buf = "__HELP_FILES__".ljust(length, '_') + ENDL
      $help_list.each do |pHelp|
        buf << " %-19.18s" % pHelp.keyword
        col += 1
        buf << ENDL if col % 4 == 0
      end
      buf << ENDL if col % 4 != 0
      buf << "Syntax:  help <topic>" + ENDL
      text_to_player buf
      return
    end

    found = Help.find(arg) # Search for arg in our help files.

    if !found
      text_to_player "No helpfile found." + ENDL
    else
      text_to_player "#{found.keyword}" + ENDL +
                     "#{found.text}" + ENDL
    end
  end

  def cmd_who command_table_entry, arg
    width = 60
    buf =  "_".center(width, '_') + ENDL
    buf << "__players_online__".ljust(width, '_') + ENDL
    $dsock_list.each do |dsock|
      next if dsock.state != :state_playing
      xPlayer = dsock.player
      next if xPlayer == nil
      buf << "=" + (" %-12s   #{dsock.addr}" % xPlayer.name).ljust(60-2) + "=" + ENDL
    end
    buf << "=".center(width, '=') + ENDL
    text_to_player buf
  end

  def cmd_wizhelp command_table_entry, arg
    col = 0
    buf = sprintf "#uImmortal Commands#u" + ENDL
    $tabWizCmd.each do |c|
      next if c.hidden
      buf << sprintf(" %-14.14s", c.cmd_name)
      col += 1
      buf << ENDL if col % 5 == 0
    end
    buf << ENDL if col % 5 > 0


    buf << "#uImplementor Commands#u" + ENDL
    $tabWizCmd.each do |c|
      next if c.hidden
      buf << sprintf(" %-14.14s", c.cmd_name)
      col += 1
      buf < ENDL if col % 5 == 0
    end
    buf << ENDL if col % 5 > 0

    text_to_player buf
  end


  def cmd_commands command_table_entry, arg
    f = format_generator

    buf = sprintf "#uCommands#u" + ENDL 
    $tabCmd.sort {|a, b| a.cmd_name <=> b.cmd_name}.each do |c|
      buf << sprintf(" %-14.14s", c.cmd_name)
      buf << f.resume
    end
    buf << ENDL
    text_to_player buf
  end

  def cmd_save command_table_entry, arg
    text_to_player "Player files are autosaved, there is no need to save manually." + ENDL
    save_pfile
  end

  def cmd_say command_table_entry, arg
    if arg == ''
      text_to_player "Say what?" + ENDL
      return
    end
    communicate self, arg, :comm_local
  end

  def cmd_qui command_table_entry, arg
    text_to_player "If you want to quit you must type it out." + ENDL
  end 

  def cmd_quit command_table_entry, arg
    # log the attempt
    log :info, sprintf("%s has left the game.", @name)
    save_pfile
    @socket.player = nil
    free_player
    @socket.close_connection
  end

  def cmd_test cte, arg
    #$room_list.each do |r|
      #r.assign_tag(Tag.gen_generic_tag(r), Tag.find_any_obj("first.area")[0])
      #r.name = DEFAULT_STRING
    #end

    log :debug, "#{Tag.get_index(Room, in_room.namespace, in_room.vtag.to_s)}"
  end

  def cmd_create cte, arg
    if arg.is_a? String
      f = format_generator 5
      text_to_player "Syntax:  create <type>" + ENDL
      text_to_player "Valid types: " + ENDL
      $editable_classes.each_pair do |k, v|
        text_to_player "#{k} "
        text_to_player f.resume
      end
      text_to_player ENDL
      return
    end

    if arg.respond_to? :create
      obj = arg.create(self)
    else
      text_to_player "Error:  No method to create from that class." + ENDL
      return
    end

    @editing=@editing || []
    @editing.unshift obj
    text_to_player "Created.  You're currently editing #{@editing[0]}." + ENDL
    execute_command("show")
  end

  
  def cmd_instance cte, arg
    found = Tag.find_any_obj arg
    if !found
      text_to_player "No object found to instance from." + ENDL
      return
    end

    if !found[0].respond_to?(:instance) 
      text_to_player "Error:  No method to instance from #{found[0].class}." + ENDL
      return
    end

    obj = found[0].instance
    text_to_player "#{examine(obj)} generated." + ENDL

    self.accept(obj) 

  end

  
  def examine thing
    if thing.is_a? Item
      "#{thing.name}"
    else
      "#{thing}"
    end
  end

  def cmd_inventory cte, arg
    text_to_player "You are carrying..." + ENDL
    each_stuff do |thing|
      text_to_player self.examine(thing) + ENDL
    end
    text_to_player "You're carrying #{count_stuff} things." + ENDL
  end

  # look up a tag of *any* object in the game space.
  def cmd_vtag cte, arg
    log :debug, arg
    tfound = Tag.find_any_obj arg

    if !tfound
      text_to_player "Nothing found." + ENDL
      return
    end

    tfound.each do |f|
      text_to_player "#{f} #{f.namespace}" + ENDL
    end
  end

  def cmd_open cte, arg
    ex = in_room.exit_list[arg]

    if !ex || !ex.flags_state.is_set?(:has_door)
      text_to_player("There is no door that direction." + ENDL)
      return
    end

    if !ex.flags_state.is_set?(:closed)
      text_to_player("That door isn't closed." + ENDL)
      return
    end
    ex.open
    text_to_player("You open the door." + ENDL)
  end

  def cmd_close cte, arg
    ex = in_room.exit_list[arg]
    if !ex == nil || !ex.flags_state.is_set?(:has_door)
      text_to_player("There is no door that direction." + ENDL)
      return
    end
  
    if ex.flags_state.is_set?(:closed)
      text_to_player("That door is already closed." + ENDL)
      return
    end
    ex.close
    text_to_player("You open the door." + ENDL)
  end
end


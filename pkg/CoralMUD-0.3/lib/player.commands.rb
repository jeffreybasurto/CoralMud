
class FormatGenerator
  def initialize length=5, opts={:sep=>"", :lf=>ENDL}
    @count = 0

    @fiber = Fiber.new do |count|
      (result = {0=>opts[:lf]}).default = opts[:sep]  # return ENDL for 0 and "" for anything else from result lookup.
      loop do
        count = Fiber.yield result[count % length]
      end
    end    
  end

  # resume the fiber.
  def resume
    @count += 1
    @last = @fiber.resume @count # and return the correct separator.
  end

  # end gracefully.
  def end
    if @last == ENDL
      ""
    else
      ENDL
    end
  end

  # return the total number of iterations.
  def count
    @count
  end  
end

$security_flags = []

class Command
  attr :cmd_name, :cmd_funct, :cmd_args, :must_type_full, :hidden
  attr_writer :cmd_args
  def initialize n, a, full=false, h=false
    @cmd_name = n
    @cmd_funct = ("cmd_"+n).to_sym

    # load this particular command now.
    Kernel::load("lib/commands/" + n + ".rb")

    @cmd_args = a
    @hidden = h
    @must_type_full = full
  end

  def hash
    [cmd_name].hash
  end

  def eql?(other)
    [cmd_name].eql?([other.cmd_name])
  end

  # returns array of strings to print out for syntax.
  def syntax
    t = @cmd_args
    t = [[t]] if !t.is_a? Array

    args = []      
    count = 0
    t.each do |expected_array|
      count += 1
      if count == 1
        str = "Syntax:  #{@cmd_name}"
      else
        str = "         #{@cmd_name}"
      end
      expected_array.each do |expected|
        # each expected arg.
        str += case expected
          when :arg_none then ""
          when :arg_dir! then " <direction>"
          when :arg_str! then " <string literal>"
          when :arg_word!then " <word>"
          when :arg_int! then " <#>"
          when :arg_obj_inv! then " <item>"
          when :arg_obj_room! then " <item>"
          when :arg_obj_inv_or_room! then " <item>"
          when :arg_class! then " <Class>"
          when :arg_player_in_game! then " <player in game>"
          when :arg_player_offline! then " <any player>"
          when :arg_actor_room! then " <npc/player>"
          when String then " " + expected          
          else ""
               
        end
      end 
      args << str
    end
    return args
  end
end



#is instanced off for player command tables.
class CommandTable
  attr_accessor :cmds
  def initialize 
    @cmds = {:secure=>[], :unsecure=>[]}
    init_cmd_table
  end

  # This is the initialize function that must be called manually to grab refernces from the global table.
  def init_cmd_table
    # Right now just adding all commands into the copied table. Maybe later a check for if is immortal or not.
    @cmds[:unsecure] = $tabCmd
    @cmds[:secure] = $tabWizCmd    
    return true
  end

  def cmd_lookup com, security = {}
    com.downcase!
    @cmds[:unsecure].each do |c|
      if c.must_type_full == true
        return c if com == c.cmd_name
      else
        return c if is_prefix com, c.cmd_name
      end
    end

    # if no security set then just go ahead and fail.
    return nil if security.empty? 
    @cmds[:secure].each do |c|
      next if !security.is_set?(c.cmd_name.to_sym)
      if c.must_type_full
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
  Command.new("look",     [[:arg_none],
                           [:arg_int!],
                           ["at", :arg_actor_room!],  
                           [:arg_actor_room!],
                           ["at", :arg_obj_inv_or_room!], 
                           [:arg_obj_inv_or_room!],
                           ["into", :arg_obj_inv_or_room!]]),


  Command.new("equipment",:arg_none),
  Command.new("wear",     :arg_obj_inv!),
  Command.new("remove",   :arg_obj_worn!),
  Command.new("put",    [[:arg_obj_inv!, "into", :arg_obj_inv_or_room!]]),
  Command.new("drop",   :arg_obj_inv!),
  Command.new("get",    [[:arg_obj_room!],[:arg_obj_inv_or_room!]]),

  Command.new("commands", :arg_none),
  Command.new("help",     [[:arg_word!], [:arg_none]]),
  Command.new("say",      :arg_str!),

  Command.new("gossip",   :arg_str!),

  Command.new("save",     :arg_none),
  Command.new("tell",     [[:arg_player_in_game!, :arg_str!],[:arg_word!, :arg_str!]]),

  Command.new("mail",     [["list"],[:arg_player_offline!, :arg_str!]]),
  Command.new("reply",    :arg_str!),
  Command.new("track",    :arg_player_in_game!),
  Command.new("open",     :arg_dir!),
  Command.new("close",    :arg_dir!),
  Command.new("inventory", :arg_none),

  Command.new("inews",    :arg_str!),
  Command.new("iruby",     :arg_str!),
  Command.new("ichat",     [[:arg_str!], [:arg_none]]),
  Command.new("icode",     [[:arg_str!], [:arg_none]]),
  Command.new("igame",     [[:arg_str!], [:arg_none]]),
  Command.new("ichannels", :arg_str!),
  Command.new("inventory", :arg_none), 
  Command.new("filter",   :arg_none),
  Command.new("spellcheck", :arg_word!),
  Command.new("omni",       :arg_none),
#imm commands moved to new table.  Most players will not need to access other table.
]

$tabCmd.uniq!

$tabWizCmd += [
  Command.new("wizhelp",  :arg_none),
  Command.new("goto",  [[:arg_player_in_game!], [:arg_str!]]),
  Command.new("sockets",  :arg_none),
  Command.new("linkdead", :arg_none),
  Command.new("reboot", :arg_none, true),
  Command.new("shutdown", :arg_none, true),
  Command.new("buildwalk",  :arg_none),
  Command.new("asave",   :arg_none),
  Command.new("vlist", [[:arg_str!], [:arg_none]]),
  Command.new("vtag", :arg_str!),
  Command.new("instance", :arg_str!),
  Command.new("create", [[:arg_class!], [:arg_str!]]),
  Command.new("edit",   [[:arg_player_in_game!],[:arg_str!],[:arg_none]]),
  Command.new("source", :arg_word!),
  Command.new("snoop",  :arg_player_in_game!),
  Command.new("purge",  :arg_none),
  Command.new("hit",      :arg_actor_room!),
  Command.new("test",     :arg_none),
  Command.new("reset",    :arg_none),
  Command.new("paint",    :arg_str!),
  Command.new("pnuke",    :arg_none),
]

$tabWizCmd.uniq!

$tabWizCmd.each do |cmd|
  $security_flags.push cmd.cmd_name.to_sym
end
$security_flags.uniq!

$global_command_table  = CommandTable.new


class String
  ### check to see if expected args exist for this string.
  ### expected must be a single dimension array.
  def check_args expected, p
    s = self.dup
    product = []
    expected.each do |arg_expected|
      return false if arg_expected == :arg_none and s != ''
      if arg_expected.is_a? String
        one_word = ""
        one_arg!(s, one_word)
        if arg_expected.start_with?(one_word.strip)
          processed = arg_expected
        else
          processed = nil
        end
      else
        processed = s.send(arg_expected, p)
      end
      return false if (processed == nil and arg_expected != :arg_none) or processed == false
      product << processed
    end

    # if the string isn't empty it's probably a fail.
    return false if !s.strip.empty?

    return product
  end
end
class Player
  ### Function to execute a command just as though it were typed.
  ### example:   player.execute("look")
  ###            player.execute("look", "at Retnur");
  def execute_command comm, arg=""
    if @editing && @editing.empty? == false
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
          pp new_arg
          if (new_arg == nil && edit_arr[0].arg_type != :arg_none)
            view "Incorrect format." + ENDL
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

    if (c = $global_command_table.cmd_lookup(comm, self.security))
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
        processed = arg.check_args each_arr, self
        next if processed == false          
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
          view c.syntax.join(ENDL) + ENDL
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
      # combine it for the query.
      comm += " " + arg
      # no command, look for a social. 
      found = Social.lookup(comm)

      if found.empty?     
        view "No such command." + ENDL
      else
        # we found some socials.
        social = found[0]
        # just do the social.
        comm_dup = comm.dup
        target = [comm_dup.arg_actor_room!(self)].flatten

        if target[0] == nil
          target = [comm.arg_obj_inv_or_room!(self)].flatten
        end
        social.execute(self, target)
      end
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

  # automatically creates new rooms and digs them out in a direction.
  # if a room is supplied we use it unconditionally.
  def buildwalk(dir, supplied=nil)
    if supplied
      if supplied.is_a?(Room)
        found = {:room=>supplied}
      else
        view "Linking failed.   Target was not a room." + ENDL
        return nil
      end
    else
      m = Automap.new(in_room, [(-1..1),(-1..1)], {:full_traverse=>true})
      found = m.find(Automap.offset([0,0], dir))
    end

    if !found
      new_room = Room.dig_rooms(in_room.vnum, Vnum.gen_vnum, dir)
      new_room.sector = in_room.sector # same sector as old room
      new_room.namespace = in_room.namespace
      new_room.assign_tag Tag.gen_generic_tag(new_room), in_room.namespace
      return new_room
    else
      Room.dig_rooms(in_room.vnum, found[:room].vnum, dir)
      return found[:room]
    end
  end
end


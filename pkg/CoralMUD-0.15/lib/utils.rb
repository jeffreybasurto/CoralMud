
def interpolate(known_data_points, x)
  xmin, xmax = nil, nil
   keys = known_data_points.keys.sort
  # find the first known x value at or below the provided x value…
  keys.reverse_each do |k|
    if k <= x
      xmin = k
      break
    end
  end
  xmin = keys[-1] if xmin == nil

  # find the first known x value at or above the provided x value…
  keys.each do |k|
    if k >= x
      xmax = k
      break
    end
  end
  xmax = keys[0] if xmax == nil
  return known_data_points[x] if known_data_points[x] != nil

  # finally, interpolate and return the answer!
  return known_data_points[xmin] + (((x - xmin) * (known_data_points[xmax] - known_data_points[xmin])) / (xmax - xmin))
end


class NilClass
  def each 
    # just to prevent an error.  If a container is nil we just treat it empty.
  end
end

class Symbol
  def sect_to_str
    case self
      when :void      then meh =  " "
      when :sect_self then meh = "#Y@"
      when :door_ns   then meh = "#P-"
      when :door_we   then meh = "#P|"
      when :track_ns  then meh = "#R|"
      when :track_we  then meh = "#R-"
      when :track_ne  then meh = "#R/"
      when :track_nw  then meh = "#R\\"
      when :track_found then meh = "#RX"
    else
      sect = Sector.lookup(self)
      wall = self == sect.symbolw
      if wall # we're dealing with a wall sector.
        meh = ("#" + sect.wall_options[0].rand + sect.wall_options[1].rand)
      else
        meh = ("#" + sect.path_options[0].rand + sect.path_options[1].rand)
      end
    end
    return meh
  end
end



def convert_mxp(s)
  state = :not_found
  # parse the string for any of the character in the regular expression. 
  # Then handle them differently dependant on the current state of the parsing as well as the individual character.
  # "<> \x03 <> \x04 <>"  should become "&lt;&gt; \x03 <> \x04 &lt;&gt;"
  s.gsub!(/["<>&\x03\x04]/) do |f|
    if state == :not_found
      state = :found if(f == "\x03")
     case f
     when "<" then "&lt;"
     when ">" then "&gt;"
     when "&" then "&amp;"
     when '"' then "&quot;"
     else f
     end  
    elsif state == :found
      state = :not_found if (f == "\x04")
      f
    end
  end
  return s
end


$bad_words = /(bitch|cunt|nigger|slut|whore|cock|dick|shit|penis|piss|fuck|cocksucker|pussy)/i
$bad_words_exact = /\b(ass|asshat|asshole)\b/i

### extend center function for strings.
class String
  ### redefine center to o_center
  alias o_center center
  alias o_ljust ljust
  alias o_rjust rjust

  # remove bad words
  def lang_filter!
    self.gsub!($bad_words, "(expletive)")
    self.gsub!($bad_words_exact, "(expletive)")
  end

  ### break a string up into an array of arguments.
  ### valid format can be any words separated by spaces or 
  def multi_args
    ss = StringScanner.new(self)
    arr = []
    loop do
      ss.scan(/\s+/) # advance any spaces that may exist.
      if ss.peek(1) == '"'
        temp = ss.scan(/".*?"/).match(/"(.*?)"/).captures[0] rescue nil
      else
        temp = ss.scan_until(/[@A-Za-z0-9._\-\/]+/)
      end

      break if !temp
      arr << temp.strip
    end
    return arr
  end

  def finalize_mxp!
    gsub!("\x03", "<")
    gsub!("\x04", ">")
    gsub!("\x05", "&")
  end

  def convert_mxp!
    state = :not_found
    # parse the string for any of the character in the regular expression. 
    # Then handle them differently dependant on the current state of the parsing as well as the individual character.
    # "<> \x03 <> \x04 <>"  should become "&lt;&gt; \x03 <> \x04 &lt;&gt;"
    gsub!(/["<>&\x03\x04]/) do |f|
      if state == :not_found
        state = :found if(f == "\x03")
        case f
        when "<" then "&lt;"
        when ">" then "&gt;"
        when "&" then "&amp;"
        when '"' then "&quot;"
        else f
        end
      elsif state == :found
        state = :not_found if (f == "\x04")
        f
      end
    end
  end


  def strip_mxp!
    mode = 0
    gsub!(/./) do |e|
      if mode == 0 # then we copy
        if e == "\x03"
          mode += 1
          ""
        else
          e
        end       
      else
        if e == "\x04" 
          mode -= 1 # down a level
          ""
        else
          ""
        end
      end
    end
  end

 

  def sub_color!
    gsub! /#[^0-9^#^ ]/, "" ### busts color
    gsub! /##/, "#"
    self
  end

  def plaintext
    s = self.dup
    s.sub_color!
    s.strip_mxp!
    s
  end

  def center count, fill=' '
    s = self.plaintext
    s.o_center(count, fill).sub(s, self)
  end

  def ljust count, fill=' '
    s = self.dup
    s.sub_color!
    s2 = s.dup
    return s.o_ljust(count, fill).sub(s2, self)
  end

  def rjust count, fill=' '
    s = self.dup
    s.sub_color!
    s2 = s.dup
    return s.o_rjust(count, fill).sub(s2, self)
  end

  def arg_class! p=nil
    command = ""
    one_arg! self, command
    return nil if command.empty?
    $editable_classes.each_pair do |k, v|
      if k.start_with? command.downcase
        return v 
      end
    end
    return nil
  end

  def arg_dir! p=nil
    s = ""
    one_arg!self, s
    return s.exit_code_to_i 
  end

 

  def arg_none p=nil
    self.strip!
    return false if !self.empty?
    return nil
  end

  def arg_tag! p=nil
    command = self.multi_args[0]
    return nil if command.empty?
    return command
  end

  def arg_str p=nil
    return nil if self == ''
    return self
  end

  def arg_str! p=nil
    return nil if self == ''
    return self.slice!(0..-1)
  end

  # see if arg is an object in the room with p
  def arg_actor_room! p=nil
    return nil if !p || self.empty?
    room = []
    room = p.in_room.stuff.select { |obj| ((obj.is_a?(NPC) || obj.is_a?(Player)) && (p != obj))}

    # parse the string, use a specific list, and it is destructive to the string.
    found = query_parse self, {"room"=>room}, true

    found.empty? ? nil : found
  end



  # see if arg is an object in the room with p
  def arg_obj_room! p=nil
    return nil if !p || self.empty?
    room = []
    p.in_room.each_stuff [ItemFacade] { |obj| room << obj }

    # parse the string, use a specific list, and it is destructive to the string.
    found = query_parse self, {"room"=>room}, true

    found.empty? ? nil : found
  end

  # obj that is worn.
  def arg_obj_worn! p=nil
    return nil if !p || self.empty?
    lists = {}
    found = []
    p.each_stuff_worn {|thing| found << thing }
    lists["equipment"] = found
    
    lists = query_parse(self, lists, true) # query the objects in inventory of p
    lists.empty? ? nil : lists
    
  end

  def arg_obj_inv! p=nil
    return nil if !p || self.empty?
    inv = []
    p.each_stuff_not_worn { |thing| inv << thing }

    lists = query_parse(self, {"inventory"=>inv}, true) # query the objects in inventory of p
    lists.empty? ? nil : lists
  end

  def arg_obj_inv_or_room! p=nil
    return nil if !p || self.empty?
    worn, inv, room = [], [], []

    p.each_stuff_worn { |obj| worn << obj }
    p.each_stuff_not_worn { |obj| inv << obj }
    p.in_room.each_stuff [ItemFacade] { |obj| room << obj }

    list = query_parse(self, {"inventory"=>inv, "worn"=>worn, "room"=>room}, true) # query the objects in inventory of p
    list.empty? ? nil : list
  end

  def arg_player_offline! p = nil
    nominations = {"offline"=>Player.all}
    found = query_parse(self, nominations, true, {:name=>:short_desc, :id=>:__id__}) 
    found.empty? ? nil : found
  end

  def arg_player_in_game! p=nil
    # may not want to select them all in the future.  Right now it does.
    list = {"game"=>$dplayer_list.select { |player| true }}
    found = query_parse(self, list, true, {:name=>:short_desc, :id=>:__id__}) # query the players and match.
    found.empty? ? nil : found
  end

  def arg_int p=nil
    command = ""
    one_arg! self, command
    return nil if command.empty?
    return Integer(command) rescue nil
  end

  def arg_int! p=nil
    command = ""
    one_arg! self, command
    return nil if command.empty?
    return Integer(command) rescue nil
  end
  def arg_word! p=nil
    command = ""
    one_arg! self, command
    if command.empty?
       nil
    else
      command
    end
  end

  ### Read up to amt characters into a new string. 
  ### If amt is greater than strlength the entire string is returned.
  def pop_some amt
    return slice! 0..(amt-1)
  end

  def pop_line
    if (pos = index("\n")) != nil then
      return slice!(0..pos).chomp
    end
    nil
  end

  def exit_code_to_i
    sel = nil
    case self
    when "north" then sel = 0
    when "east"  then sel = 1
    when "south" then sel = 2
    when "west"  then sel = 3
    when "up"   then sel = 4
    when "down"  then sel = 5
    when "0" then sel = 0
    when "1" then sel = 1
    when "2" then sel = 2
    when "3" then sel = 3
    when "4" then sel = 4
    when "5" then sel = 5
    end
    return sel
  end
  def get_player
    $dplayer_list.each do |xplay|
      #return the player if they match the name.
      return xplay if xplay.name.start_with? self
    end
    return nil
  end

  # returns an array ordered pair of [x, y].  This will throw an exception that can be rescued if it is invalid.
  def get_coords
    gsub!(/[,.]/, ' ')
    a = split(' ')

    if (a[0] != nil && a[1] != nil && a[0].is_number? && a[1].is_number?)
      a[0], a[1] = Integer(a[0]), Integer(a[1])
      return a
    end
    raise "Invalid coordinates."
    return [0,0]
  end

  # returns true or false. 
  def is_coords?
    (get_coords rescue false) ? true : false
  end

  #check to see if a number
  def is_number?
    if (Integer(self) rescue false)
      true
    else
      false
    end
  end
end

### Extension for rounding a floating point.
class Float
  def roundf(places)
    temp = self.to_s.length
    sprintf("%#{temp}.#{places}f",self).to_f
  end
end
### Extension for various Integers
class Integer
  def exit_code_to_s
    ea = ["north", "east", "south", "west", "up", "down"]

    return nil if (self > 5 || self < 0)
    return ea[self]
  end

  def exit_code_rev
    ea = [2, 3, 0, 1, 5, 4]

    return nil if (self > 5 || self < 0)
    return ea[self]
  end

  def commify
    str = "#{self}"
    str.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end
end

### Check to see if a given name is valid
def check_name name
  return false if (name.size < 3 || name.size > 12)
  if name =~ /^[[:alpha:]]+$/
    return true
  else
    return false
  end
end

### Check to see if password is valid for new password.
def check_pass pass
  return false if (pass.length < 3 || pass.length > 12)

  pass.length.times do |i|
    if pass[i].chr == '~'
      return false
    end
  end

  return true
end

def communicate author, txt, range, called=nil
  filtered = txt.dup
  filtered.lang_filter!
  case range
    when :comm_local
      called = "say" if !called
      author.view("#CYou #{called}, '#{author.channel_flags.is_set?(:language_filter)? filtered : txt}'#n" + ENDL)
      called = called.en.plural
      in_room.display([:visual, :sound, "other.can_see?(actor) || other.can_hear?(actor)"], self, [self],
           "#C<%=other.peek(actor)%> #{called}, '<%=other.listen(other.channel_flags.is_set?(:language_filter) ? arg[1] : arg[0], actor)%>#n'", txt, filtered)
    when :comm_global
      called = "gossip" if !called

      called = called.en.plural
      author.view "#PYou #{called}, '#{author.channel_flags.is_set?(:language_filter)? filtered : txt}'#n" + ENDL
      $dplayer_list.each do |other|
        next if other == author
        other.view "#P#{other.peek(author)} #{called}, '#{other.channel_flags.is_set?(:language_filter)? filtered : txt}'#n" + ENDL
      end
    when :comm_private
      # not implemented
  end
end


### Loading of help files, areas, etc, at boot time.
def load_muddata
  load_helps
end

### Check to reconnect a player.
### Called in core nanny coroutine.
def check_reconnect name
  $dplayer_list.each do |dPlayer|
    if dPlayer.name.downcase == name.downcase
      dPlayer.socket.close_connection true if dPlayer.socket
      return dPlayer
    end
  end
  nil
end

### Checks if aStr is a prefix of bStr.
def is_prefix astr, bstr
  return false if astr.nil? || bstr.nil? || astr.empty? || bstr.empty?
  astr == bstr.slice(0...astr.size)
end

def one_arg fstr, bstr, nums_too = true
  bstr.replace(fstr.slice(if nums_too then /[0-9a-zA-Z@:_\.-]+/ else /[a-zA-Z@:_\.-]+/ end) || '')
end

### Breaks a string down into a single argument.
def one_arg! fstr, bstr, nums_too = true
  bstr.replace(fstr.slice!(if nums_too then /[0-9a-zA-Z@:_\.-]+/ else /[a-zA-Z@:_\.-]+/ end) || '')
  fstr.lstrip!
end

###
### Detects the last time the file was edited.
def last_modified file
  return File.stat(file).mtime.to_i
rescue
  return 0
end


# distance form
def dist_form(a1, a2)
  Math.sqrt( (a2[0] - a1[0])**2 + (a2[1] - a1[1])**2)  
end

# find the azimuth of the direction towards target
def get_azi a, b
  # find the distance between the two points.
  hyp = dist_form a, b

  adj = (b[1] - a[1])

  #which hemisphere?
  if (b[0] - a[0]) >= 0
    d = 0
  else
    adj = -adj
    d = 180
  end

  # cos^-1 (adj/hyp) * 180/PI  
  r = Math::acos(adj/hyp) # answer in radians
  d = r * 180 / Math::PI + d
end


def find_player arg
  $dplayer_list.each do |xPlayer|
    return xPlayer if is_prefix arg.capitalize, xPlayer.name
  end
  return nil
end

def strip_color txt
  txt.gsub! 
end

# takes a string and returns a string with color codes added.
def render_color(data)
  data.gsub!($comp_tab) do |s|
    $color_table[s]
  end
  return data
end

def render_color2(data)
  return data
end

def text_to_world txt
  $dsock_list.each do |d|
    d.text_to_socket txt
  end
end


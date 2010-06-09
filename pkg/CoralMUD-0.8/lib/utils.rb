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


### extend center function for strings.
class String
  ### redefine center to o_center
  alias o_center center
  alias o_ljust ljust
  alias o_rjust rjust

  ### break a string up into an array of arguments.
  ### valid format can be any words separated by spaces or 
  def multi_args 
    ss = StringScanner.new(self)
    arr = []

    loop do 
      ss.scan(/\s/) # advance any spaces that may exist.
      if ss.peek(1) == ':'
        temp = ss.scan(/\:/)
      elsif ss.peek(1) == '"' # peed at the next character.
        temp = ss.scan(/".*?"/) # Scan it in.
        break if !temp
        temp.strip 
        temp[-1] = ""
        temp[0] = ""
      else
        temp = ss.scan_until(/\w+/)
      end
      if !temp
        break
      end
      arr << temp.strip 
    end
    

    arr
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
 #   s = self.dup # dup self
 #   s.sub_color! # strip color
 #   s.strip_mxp! #strip mxp
 #   s2 = s.dup # s and s2 are the same.  self is original string

    # self at this point still hash color codes and MXP tags.
    # matches and replaces back into it after we format based on the string without either.
 #   return s.o_center(count, fill).sub(s2, self)i
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

  def arg_class!
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

  def arg_dir
    return self.exit_code_to_i 
  end

  def arg_none
    return nil
  end

  def arg_tag!
    command = self.multi_args[0]
    return nil if command.empty?
    return command
  end

  def arg_str
    return nil if self == ''
    return self
  end

  def arg_player_in_game!
    command = ""
    one_arg! self, command
    return nil if command.empty?
    return find_player(command)
  end
  def arg_int!
    command = ""
    one_arg! self, command
     
    return nil if command.empty?
    return Integer(command) rescue nil
  end
  def arg_word!
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

### Communication Ranges
### Can add more.  Eventually will need to figure out systems for if a player can see another player, etc.
### :comm_local           =  0  # same room only
### :comm_log             = 10  # admins only
def communicate dPlayer, txt, range
  buf = ""
  msg = ""

  case range
    when :comm_local 
      dPlayer.text_to_player sprintf "#CYou say, '%s'#n\r\n", txt
      $dplayer_list.each do |xPlayer|
        next if xPlayer == dPlayer
        #next if xPlayer.in_room != dPlayer.in_room
        xPlayer.text_to_player sprintf "#C%s says, '%s'#n\r\n", dPlayer.name, txt
      end
    when :comm_log
      msg = sprintf "[LOG: %s]\r\n", txt
      puts msg
      $dplayer_list.each do |xPlayer|
        next if !xPlayer.is_admin?
        xPlayer.text_to_player msg
    end
  else
    log :error, "Communicate: Bad Range %d.", range
    return;
  end
end

### Loading of help files, areas, etc, at boot time.
def load_muddata
  load_helps
end

### Check to reconnect a player.
### Called in core nanny coroutine.
def check_reconnect player
  $dplayer_list.each do |dPlayer|
    if dPlayer.name.casecmp(player) == 0
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

### Breaks a string down into a single argument.
def one_arg! fstr, bstr
  bstr.slice! 0..-1
  bstr << (fstr.slice!(/\w+/) || '')
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



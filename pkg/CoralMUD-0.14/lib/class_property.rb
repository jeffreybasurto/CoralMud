class Object
  # everything can have an owner.
  attr_accessor :owner

  # easier definition for accessing a metaclass.
  def metaclass
    class << self; self; end
  end

  # simply mark this item as destroyed for intents of the game engine.
  def recycle
    @recycled = true
  end
  # ist his item recycled?
  def recycled?
    @recycled == true 
  end
end

# Storable items can be placed in inventory.
module Storable
end

$editable_classes = {}


module CoralMUD

  module LivingEntity
    include HealthPool

    def inventory
      stuff.select{|o| o.is_a? Item} - worn_items
    end

    def each_stuff_not_worn
      inventory.each {|item| yield item}
    end

    def each_stuff_worn
      self.worn_items.each { |item| yield item, item.worn_on }
    end
   
 
    def in_room
      @owner
    end
    attr_accessor :wearing

    def is_npc?
      return is_a?(NPC)
    end

    def is_blind?
      false
    end

    def is_mute?
      false
    end

    def is_numb?
      false
    end

    def is_deaf?
      false
    end

    def can_hear? something
      case something
        when String
          return !is_deaf? 
        when NpcFacade, Player, ItemFacade
          return !is_deaf?  # it's possible we will have ways to communicate without having to hear it.
      end
    end

    def can_see? thing
      if is_blind?
        false
      end
      true
    end


    def short_desc
      return @name
    end

    # just return the items being worn right now.
    def worn_items
      if !@wearing
        return []
      end

      return @wearing.values
    end

    def remove obj
      @wearing = {} if !@wearing
      @wearing.delete_if {|v,k| k == obj }
    end

    # wear an obj in one of the locations checking them in order for empty spots.
    def wear obj, locations=obj.worn_locs
      locations = [locations].flatten

      @wearing = {} if !@wearing

      # find the first location with nothing in it.
      locations.each do |a_loc|
        if !@wearing[a_loc] 
          @wearing[a_loc] = obj
          obj.worn_on = a_loc
          return true # bingo
        end
      end
      return false
    end

    # get an object from the room
    def get obj
      if obj.is_a? Array
        obj.each do |o|
          get(o) 
        end
      else
        obj.owner.remove obj
        accept obj
      end
    end

    # drop some this thing has
    def drop obj
      if obj.is_a? Array
        obj.each do |o|
          drop(o)
        end
      else
        obj.owner.remove obj
        in_room.accept obj
      end
    end

    def to_room  room  ### anything including this should may be placed into a room.
      if room.is_a? Integer
        r = Vnum.get_room_index(room)
        r = goto_make_room room if !r
        room = r
      end
      room.accept_player(self)
    end

    def from_room
      if in_room != nil
        in_room.remove_player(self)
      end
      in_room = nil
    end
    def is_imm?
      if @level
        return @level >= LEVEL_IMM
      end
      false
    end

    def is_admin?
      return @level == LEVEL_ADMIN if @level
      false
    end

    def listen thing, author
      if can_hear?(author)
        "#{thing}"
      else
        "something"
      end
    end

    def peek thing, a=true, full=true, just_path=false
      orig_thing = thing
      name = ""
      if thing.is_a? Array
        if thing.empty?
          return "nothing"
        end
        # it's an array of things to peek at, at once.
        found = []
        thing.flatten!
        paths = []
        thing.each do |element|
          found << peek(element, false, false)
          paths << peek(element, false, true, true)
        end
        paths.uniq!
        name += (found.en.conjunction).gsub(/\ban?\s+([A-Z])/, '\1')
        if full
          if paths.count == 1
            name += paths[0]
          else
            name += " in #{"source".en.quantify(paths.count)}"
          end
        end
      else
        count = 0
        # do while loop.
        loop do
          count += 1
          a = true if count == 2
          begin
            a = false if thing.is_a? Player
            s = a ? thing.short_desc.en.a : (thing.short_desc + if thing.socket then "" else "(linkless)" end)
          rescue
            s = "#{thing}"
          end
 
          break if thing == self || !thing.owner && thing != orig_thing
          name += case count
            when 1 then ""
            when 2 
              " from "
            else
              " in "
          end
          name += s if !just_path || count > 1
          thing = thing.owner
          break if !full
          break unless thing
        end
      end
      return name
    end

    def view obj
      if @socket
        case obj
        when String then @socket.text_to_socket obj
        when CoralMUD::LivingEntity # anything that supports this module.
          view "#{peek(obj).capitalize} has no distinguishing features." + ENDL

          if !obj.worn_items.empty?
            view "#{peek(obj).capitalize} is wearing:" + ENDL
            obj.each_stuff_worn do |item, location|
              view "#{location} " + peek(item, true, false) 
            end
          end
  
          view "#{peek(obj).capitalize} is carrying:" + ENDL
          found = []
          obj.each_stuff_not_worn do |item|
            found << item
          end
          view peek(found, true, false) + ENDL
        when ItemFacade,Player, NpcFacade # only reaches here if not defined when above here.  
          # description would eventually be here.
          view "#{peek(obj).capitalize} has no distinguishing features." + ENDL
        else
          view "#{obj}"
        end
      end
    end

    def text_to_player txt
      if @socket
        @socket.text_to_socket txt
      end
    end

    def go_anywhere
      found = nil

      log :info, "Moving someone."

      in_room.exit_list.each do |ex|
        next if ex == nil
        ex.enter(self)
        return
      end

      in_room.remove_player(self)
      r = Vnum.get_room_index(1)
      if r == nil
        r = goto_make_room 1
      end
      r.accept_player(self)
    end
  end

  module HasStuff    
    # put anything in this room in the generic list for stuff.
    def accept thing
      if self.respond_to? :can_accept?
        if !self.can_accept? thing
          return false
        end
      end
      @stuff = [] if !@stuff
      @stuff << thing
      thing.owner = self
      return true
    end

    def stuff
      @stuff || []
    end

    # remove anything from this room.
    def remove thing
      if self.respond_to? :can_remove?
        if !self.can_remove? thing
          return false
        end
      end

      thing.owner = nil

      @stuff.delete thing if @stuff
      @stuff = nil if @stuff && @stuff.empty?
      return true
    end

    

    def each_stuff of_type=Object
      @stuff.each do |thing| 
        case thing
        when *of_type
          yield thing 
        end
      end
    end

    def count_stuff of_type=Object
      c = 0
      @stuff.each {|thing| c += 1 if thing.is_a?(of_type)}
      return c
    end
  end

  module VirtualTags
    attr_accessor :vtag, :namespace
    def assign_tag tag_str, namespace=nil
      # do minimal checking to make sure the tag doesn't already exist.
      if @vtag 
        Tag.clear_tag(self)
      end
      @vtag = Tag.new(tag_str, self, namespace) # generate a tag.
      @namespace = namespace
    end
    def reassociate_tag namespace=nil
      @vtag.reassociate(self, namespace)

      @namespace = namespace
    end


    # Note: Most of the code involving the VirtualTag system is in tags.rb.
  end

  # If class can be written to file.
  module FileIO
    # Save any class to a file. Path should be given to the directory to save in.
    # example:  "player/Retnur.yml"
    def save_to_database
      begin 
        str_to_write = YAML::dump gen_configure
        self.extra_data = str_to_write
        self.save
      rescue Exception=>e
        log :error, "Unable to write to database: #{self}"
        log_exception e
      end
    end

    # Load and configure a class from their database definition.
    def load_from_database
      begin
        a = YAML::load self.extra_data
        @when = Time.now.to_i 
      rescue Exception=>e
        log_exception e
        log :error, "unable to load YAML."
        return nil
      end
      begin
        configure(a)
        return self
      rescue Exception=>e
        log_exception e
        log :error, "Unable to configure: #{dir}"
        return nil
      end
    end


    def save_to_file file
      begin
        config = gen_configure
        str_to_write = YAML::dump config
        File.open( file, 'w' ) do |out|
          out.puts str_to_write
        end
      rescue Exception=>e
        log :error, "Unable to write: #{file}"
        log_exception e
      end
    end
 
    # Load and configure a class from a file.   Path should be given to the directory to load from.
    # example:  "player/Retnur.yml"
    def load_from_file dir
      begin 
        a = YAML::load_file dir
        @when = Time.now.to_i # For finding out later if it needs to be reloaded.
                              # Class may or may not even make use of this.   Adding it at the time for help file support.
      rescue Exception=>e
        log_exception e
        log :error, "unable to load YAML."
        return nil
      end
      begin
        configure(a)
        return self
      rescue Exception=>e
        log_exception e
        log :error, "Unable to configure: #{dir}"
        return nil
      end
    end

    # convert map to instance.
    def configure data
      version = data[:version]

      # Note: These hooks do *not* need to be defined. 
      # They're only defined if you're using version controlling
      # or if you want more control on how data is transformed beyond generics.
      # hook for calling version_control
      if self.respond_to?:version_control
        data = self.version_control(version, data)
      end

      # Hook for calling data_transform
      if self.respond_to?:data_transform_on_load
        data = self.data_transform_on_load(version, data)
      end

      # load hash into object directly.   
      data.each do |key, value|
        if value.is_a?(String) && value == DEFAULT_STRING
          self.instance_variable_set(key, DEFAULT_STRING) # save a little memory.
        else
          self.instance_variable_set(key, value) # sets all instance variables by name of key.
        end
      
      end
    end

    # generate the hash we save.
    def gen_configure
      if respond_to?(:to_configure_properties) 
        #If this method is defined it will return an array of variables we must add to this hash.
        config_list = to_configure_properties

        data = {}
        # for each item we must configure...
        config_list.each do |item|
          val = instance_variable_get(item) # grab the value for this key
          data[item] = val # sets the value in our hash
        end

        # hook for transforming the data if need be.
        if respond_to?(:data_transform_on_save)
          data = data_transform_on_save(data)
        end
        return data
      end
    end
  end
end


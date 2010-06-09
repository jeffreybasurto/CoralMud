# Anything that actually exists and can be placed in Rooms should mix this in.
module Movable
  attr_accessor :in_room
  def to_room  room  ### anything including this should may be placed into a room.
    if room.is_a? Integer
      r = get_room_index(room)
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
end

# Storable items can be placed in inventory.
module Storable
end

module CoralMUD
  module VirtualTags
    attr_accessor :vtag, :namespace

    def assign_tag tag_str, namespace=nil
      # do minimal checking to make sure the tag doesn't already exist.
      @vtag = Tag.new(tag_str, self, namespace) # generate a tag.
      @namespace = namespace
    end


    # Note: Most of the code involving the VirtualTag system is in tags.rb.
  end

  # If class can be written to file.
  module FileIO
    # Save any class to a file. Path should be given to the directory to save in.
    # example:  "player/Retnur.yml"
    def save_to_file file
      begin
        File.open( file, 'w' ) do |out|
          YAML::dump gen_configure, out
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
        self.instance_variable_set(key, value) # sets all instance variables by name of key.
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

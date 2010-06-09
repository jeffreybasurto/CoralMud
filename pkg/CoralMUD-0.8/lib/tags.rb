class String
  def derive_tag
    s = self.dup
    s.gsub!(/[,.]/, ' ') # replace a."smelly yet lovely".cat with a smelly cat
    s.gsub!("::", " : ")
    a = s.multi_args      # turn ["a", "smelly yet lovely", "cat"]
    n_a = [[]]
    a.each do |each_word|
      if each_word == ":"
        n_a.unshift([])
        next
      end
      n_a[0] << each_word
    end

    n_a
  end
end

class Array
  def revert_tag
    return self[0].join '.'
  end
end

class Tag 
  @@classes_with_tags = {}
  def to_yaml_properties
    ['@vtag']
  end

  # tag_str is in the format of a.stinky.cat
  def initialize tag_str, obj, namespace=nil
    Tag.clear_tag obj
    @vtag = tag_str.derive_tag
    obj.namespace = namespace
    @@classes_with_tags[[obj.class, namespace, @vtag.revert_tag]] =  obj # The specific class and the specific tag are the key to looking up the obj  
  end


  # intended to be a fast lookup if you have all the keys.
  def self.get_index typeof, namespace, tag
    @@classes_with_tags[[typeof, namespace, tag]]
  end

  # search for all objects of a specific type.
  def self.search_class typeof
    @@classes_with_tags.each_pair do |keys, obj|
      yield obj if keys[0] == typeof
    end
  end

  # search for all objects part of a specific namespace.
  def self.search_namespace namespace=nil
    @@classes_with_tags.each_pair do |keys, obj|
      yield obj if keys[1] == namespace
    end
  end

  # returns the full tag representing an object.  Builds it somewhat dynamically and relies heavily on uncorrupted data.
  def self.full_tag obj
    arr = []
    while obj
      arr.unshift obj.vtag.to_s
      obj = obj.namespace #
    end
    arr.join "::" # should build something like  a.continent::a.area 
  end

  def reassociate obj, namespace=nil
    Tag.clear_tag obj
    obj.namespace = namespace
    if @@classes_with_tags[[obj.class, namespace, @vtag.revert_tag]]
      obj.assign_tag Tag.gen_generic_tag(obj), namespace
    end
    @@classes_with_tags[[obj.class, namespace, @vtag.revert_tag]] =  obj # The specific class and the specific tag are the key to looking up the obj  
  end

  # generates a tag like:   alpha.fife or foxtrot.niner
  def self.gen_generic_tag obj
    alpha_data = %w{ alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu }
    num_data = %w{ wun too tree fower fife siks seven ait niner zeero }
    alpha_range = ('a'..'zzz')
    numeric_range= (1..100)

    alpha_data.each do |alpha|
      numeric_range.each do |numeric|
        tag_str = "#{obj.class.to_s.downcase}.#{alpha}.#{numeric}"
        if @@classes_with_tags[[obj.class, obj.namespace, tag_str]] == nil
          return tag_str
        end
      end
    end
  end

  def to_s
    @vtag.revert_tag
  end

  # compare this tag to either a string
  def ==(val)
    a1 = val
    a2 = @vtag[0].dup
    a1.sort!
    a2.sort!

    # for each word in a1 make sure *any* word minimally matches in a2
    a1.each do |word|
      i = 0
      found = false
      loop do
        return false if !a2[i]
        if a2[i].start_with?(word)  # if this is a match we need to make sure that array position id deleted.  It can't be used again to match
          found = true
          a2.delete_at(i) # delete this position
          break
        end
        i += 1
      end
      return false if !found # if this match didn't pass return false.
    end
    return true
  end

  def self.clear_tag obj
    @@classes_with_tags.delete_if do |k, v| 
      v == obj
    end
  end

  def self.find_any_obj tag_str, of_type=nil
    found = []
    arg_arr = tag_str.derive_tag if tag_str.is_a?(String) # derive the tag array
    # search the hash for this exact key exists
    @@classes_with_tags.each_pair do |keys, obj|
      next if of_type && !obj.is_a?(of_type)

      if obj.vtag == arg_arr[0]
        # ["obj"], ["area"], ["world"]
        # Match further only if arg_arr has additional namespaces.
        if arg_arr.count > 1 
          # Also, this obj is not a match unless it actually supports more name spaces.
          next if !obj.namespace 

          temp = arg_arr.dup # dup it so we can shift from the top.
          temp.shift # remove the one we already examined.   Now we only have name spaces.

          err = false
          next_o = obj.namespace # next_o is the obj's namespace.
          while !temp.empty? do
            if !next_o
              err = true
              break
            end
            t_el = temp.shift
            if !(next_o.vtag == t_el) # match it with the obj's vtag.  If it's a fail then look up the tree.
              err = true
              while (next_o = next_o.namespace) != nil
                if next_o.vtag == t_el
                  err = false
                  break 
                end 
              end
              break if err == true
            end
            next_o = next_o.namespace
          end

          next if err
        end
        found << obj
      end
    end
    return nil if found.empty?
    found # returns all found objects and their namespace. 
  end

end


class TestWorld
  attr_accessor :vtag
  attr_accessor :namespace
  def initialize tag_str
    @vtag = Tag.new(tag_str, self)
  end
end

class TestArea
  attr_accessor :vtag, :namespace
  def initialize tag_str, obj=nil
    @vtag = Tag.new(tag_str, self, obj)
  end
end

class TestRoom
  attr_accessor :vtag, :namespace
  def initialize tag_str, obj=nil
    @vtag = Tag.new(tag_str, self, obj)
  end
end


w1 =TestWorld.new('the.world')
a1 = TestArea.new("an.area", w1)
a2= TestArea.new("a.area", w1)
r1= TestRoom.new("ugly.room.south", a1)
r2= TestRoom.new("ugly.room.north", a2)
tfound = Tag.find_any_obj 'u.r'
log :debug, "#{tfound[0]} #{tfound.count}" if tfound
log :debug, "#{Tag.full_tag r1}"

class NilClass
  def is_set key
    return false
  end
  alias is_set? is_set

  # prefix is used to tell teh method the MXP command if it's not the default path.  
  def display_flags key, prefix="flags", how_much_buffer=0
    str = ""
    total = how_much_buffer
    key.each do |flag|
      # if this flag is set here then we return it green.  Otherwise red.
      str << " "
      node_prefix = mxptag("send \"#{prefix} #{flag}\"")
      node = "#R[ ]#{flag}"
      total += node.length - 1

      if total >= 74
        str << ENDL
        total = node.length - 1
      end
      str << node_prefix + node
      str << mxptag('/send')
    end
    return str
  end
end
class Hash
  # returns true if flag is set.
  # false if flag is removed.
  def toggle sym
    if self[sym]
      self.delete(sym) # remove the flag
      return false
    end
    self[sym] = true
    return true
  end

  def is_set sym
    return true if self[sym] != nil
    return false
  end
  alias is_set? is_set

  # set a flag
  def set sym
    self[sym] = true
  end

  # remove a flag
  def remove sym
    self.delete(sym)
  end

  # prefix is used to tell teh method the MXP command if it's not the default path.  
  def display_flags key, prefix="flags", how_much_buffer=0
    str = ""
    key = self.keys + key
    key.uniq!

    total = how_much_buffer
    key.each do |flag|
      str << " "
      # if this flag is set here then we return it green.  Otherwise red.
      node_prefix = mxptag("send \"#{prefix} #{flag}\"") 

      node = ("%s" % ("%s#{flag}" % (if self.include?(flag) then "#G[x]" else "#R[ ]" end)))
      node += "=#{self[flag]}" if self[flag] != nil and self[flag] != false and self[flag] != true

      total += node.length - 1

      if total >= 79
        str << ENDL
        total = node.length - 1
      end

      str << node_prefix + node
      str << "#n"+mxptag('/send')

    end
    return str
  end
end


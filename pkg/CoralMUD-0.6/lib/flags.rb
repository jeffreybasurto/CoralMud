
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
  def display_flags key, prefix="flags"
    str = ""
    key.each do |flag|
      # if this flag is set here then we return it green.  Otherwise red.
      if self.include?(flag)
        found = true
        str << " #G[x]"
      else
        found = false
        str << " #R[ ]"
      end
      if prefix
        str << mxptag("send \"#{prefix} &text;\"") + "#{found == true ? "#G" : "#R"}" + "#{flag}" + mxptag('/send') 
      else
        str << "#{flag}"
      end

      str << "=#{self[flag]}" if self[flag] != nil and self[flag] != false and self[flag] != true
      str <<  mxptag('/c') if prefix

    end
    return str
  end
end


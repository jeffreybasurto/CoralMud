

class String
  alias old_split split

  def split arg, limit=nil
    val = case limit
    when nil then old_split(arg)
    else old_split(arg, limit)
    end

    if val.empty?
       val = [""]
    end
    
    return val
  end
end



p "".split("")

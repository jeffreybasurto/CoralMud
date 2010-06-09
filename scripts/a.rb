class String
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
    self.dup.sub_color!.strip_mxp!
  end

  def testc count, fill=' '

   s = self.dup # dup self
   s.sub_color! # strip color
   s.strip_mxp! #strip mxp
   s2 = s.dup # s and s2 are the same.  self is original string

    # self at this point still hash color codes and MXP tags.
    # matches and replaces back into it after we format based on the string without either.
   s.center(count, fill).sub(s2, self)
  end
#    s = self.plaintext
#    s.center(count, fill).sub(s, self)
end


str = "roar roar"
100000.times do 
  str.testc(10)
end

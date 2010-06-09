class String
  def sub_color!
    gsub! /#[^0-9^#^ ]/, "" ### busts color
    gsub! /##/, "#"
  end
end

def center_text text, width=80, padding_str=' '
  stripped_text = text.dup
  stripped_text.sub_color!
  # If this doesn't return a whole number, this will ensure we still take up
  # the entire width
  padding_left = ((width-stripped_text.length)/2).floor
  padding_right = ((width-stripped_text.length)/2).ceil
  "#{padding_str*padding_left}#{text}#{padding_str*padding_right}"
end

1000.times do 
  center_text "#r#r#w#gtest string", 20, '_'
end


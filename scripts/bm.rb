s = "roar <test> \x03 <somefin> \x04 <test> \x03 <test 2> <somefin else> \x04"

state = :not_found
# parse the string for any of the character in the regular expression. 
# Then handle them differently dependant on the current state of the parsing as well as the individual character.
# "<> \x03 <> \x04 <>"  should become "&lt;&rt; \x03 <> \x04 &lt;&rt;"
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
    if f == "\x04"
      state = :not_found
    end
    f
  end
end
# and replace the other stuff
s.gsub!("\x03", "<")
s.gsub!("\x04", ">")

p s

require 'strscan'
class String
  ### break a string up into an array of arguments.
  ### valid format can be any words separated by spaces or 
  def multi_args
    ss = StringScanner.new(self)
    arr = []
    loop do
      ss.scan(/\s+/) # advance any spaces that may exist.
      if ss.peek(1) == '"' 
        temp = ss.scan(/".*?"/).match(/"(.*?)"/).captures[0]
      else
        temp = ss.scan_until(/[A-Za-z0-9._-]+/)
      end

      break if !temp
      arr << temp.strip
    end 
    return arr
  end
end

test_cases = ["---------------------",
              "all separate words.",
              "---------------------",
              'three "phrases are" separate', 
              "---------------------",
              '"all one phrase"']

test_cases.each do |phrase|
  puts phrase.multi_args
end

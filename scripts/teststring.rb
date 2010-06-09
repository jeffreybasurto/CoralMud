 
# Basically, the parsing methods will be passed a string in typical ROM format:
#
# !RThis test should be red and !Bthis text should be blue.!X
#
# In ROM, I think the escape character is "{", but I'm using "!" here just
# because it looks better :)
 
require "benchmark"
#require "jcode"
require "singleton"
 
class ColorBenchmark
 
  include Singleton
 
  COLOR_ESC = "!"
 
  COLORS =
  {
    "x"        => "\e[0m",     # Reset
    "X"        => "\e[0m",     # Reset
    "u"        => "\e[4m",     # Underline
    "U"        => "\e[4m",     # Underline
    "i"        => "\e[7m",     # Inverse
    "I"        => "\e[7m",     # Inverse
    "k"        => "\e[0;30m",  # Normal intensity black
    "r"        => "\e[0;31m",  # Normal intensity red
    "g"        => "\e[0;32m",  # Normal intensity green
    "y"        => "\e[0;33m",  # Normal intensity yellow
    "b"        => "\e[0;34m",  # Normal intensity blue
    "m"        => "\e[0;35m",  # Normal intensity magenta
    "c"        => "\e[0;36m",  # Normal intensity cyan
    "w"        => "\e[0;37m",  # Normal intensity white
    "K"        => "\e[1;30m",  # High intensity black
    "R"        => "\e[1;31m",  # High intensity red
    "G"        => "\e[1;32m",  # High intensity green
    "Y"        => "\e[1;33m",  # High intensity yellow
    "B"        => "\e[1;34m",  # High intensity blue
    "M"        => "\e[1;35m",  # High intensity magenta
    "C"        => "\e[1;36m",  # High intensity cyan
    "W"        => "\e[1;37m",  # High intensity white
    COLOR_ESC  => COLOR_ESC    # Escape character
  }
 
  TEST_ITER   = 10_000
  TEST_STR    = "#{COLOR_ESC}R@#{COLOR_ESC}r@#{COLOR_ESC}Y@#{COLOR_ESC}y@" +
                "#{COLOR_ESC}G@#{COLOR_ESC}g@#{COLOR_ESC}B@#{COLOR_ESC}b@" +
                "#{COLOR_ESC}C@#{COLOR_ESC}c@#{COLOR_ESC}M@#{COLOR_ESC}m@" +
                "#{COLOR_ESC}W@#{COLOR_ESC}w@#{COLOR_ESC}K@#{COLOR_ESC}k@" +
                "#{COLOR_ESC}X#{COLOR_ESC}Ii#{COLOR_ESC}X#{COLOR_ESC}Uu" +
                "#{COLOR_ESC}x#{COLOR_ESC}#{COLOR_ESC}"
  TEST_REF    = "\e[1;31m@\e[0;31m@\e[1;33m@\e[0;33m@\e[1;32m@\e[0;32m@" +
                "\e[1;34m@\e[0;34m@\e[1;36m@\e[0;36m@\e[1;35m@\e[0;35m@" +
                "\e[1;37m@\e[0;37m@\e[1;30m@\e[0;30m@\e[0m\e[7mi\e[0m\e[4mu\e[0m!"
 
  @expression = []
  COLORS.each_key do |entry|
    @expression << COLOR_ESC + entry
  end
  @expression = Regexp.union(*@expression)

  def run()
    puts "\nBenchmarking #{TEST_ITER} iterations:\n\n"
    puts "Reference  #{TEST_REF}"
    parsers = []
 
    # Find all the parse methods
    methods.sort.each do |p|
      if /^parse\d+$/ =~ p
        m      = method( p )
        out    = m.call( TEST_STR )
        valid  = ( out == TEST_REF ? "" : " -- Invalid!" )
        puts sprintf( "%-10s %s%s", p, out, valid )
        parsers  << p if valid == ""
      end
    end
 
    puts "\n"
 
    # Start the benchmarking
    Benchmark.bm( 10 ) do |bm|
      parsers.each do |p|
        m = method( p )
        bm.report( p ) { TEST_ITER.times { m.call( TEST_STR ) } }
      end
    end
  end
 
  # Iterate each character of the String keeping state because I don't know how
  # to advance the pointer :(
  def parse1( str )
    found_esc  = false
    out        = ""
    str.each_char do |c|
      if found_esc
        out << COLORS[c]
        found_esc = false
        next
      end
      if c == COLOR_ESC
        found_esc = true
        next
      else
        out << c
      end
    end
    return out
  end
 
  # One-pass gsub.  It's sort of cheating, though, since any added codes in the
  # future will have to be added to the Regex, as well.  Shrug.
  def parse2( str )
    out = str.dup
    out.gsub!(@expression) do |code|
      COLORS[code[1,1]]
    end
    return out

  end

  # Iterates the hash and gsubs each pair individually.
  def parse3( str )
    out = str.dup
    COLORS.each do |key,val|
      out.gsub!( /#{COLOR_ESC}#{key}/, val )
    end
    return out
  end
 
  # Same as parse2, only giving gsub a String param instead of a Regex.
  def parse4( str )
    out = str.dup
    COLORS.each do |key,val|
      out.gsub!( "#{COLOR_ESC}#{key}", val )
    end
    return out
  end


  def parse5( str )
    out = str.dup
    out.gsub!(EXPRESSION) do |code|
      COLORS[code[1,1]]
    end
    return out
  end 
end
 
ColorBenchmark.instance.run()
puts "\n"
 

class Help
  attr_accessor :keyword, :text, :when
  include CoralMUD::FileIO # for saving routines.

  # lookup a help file currently loaded by a string.
  # Also load from file if newer version exists.
  def self.find arg
    $help_list.each do |a_help|
      if a_help.keyword.start_with?(arg.upcase)
        if last_modified("help/#{a_help.keyword}.yml") > a_help.when
          a_help.load_from_file("help/#{a_help.keyword}.yml") # load it again.
        end
        return a_help
      end
    end

    return nil # nothing was found
  end
  # Properties to save/load.
  def to_configure_properties
    ["@keyword", "@text"]
  end
end

#save all help files
def save_helps
  log :info, "Saving all help files."
  $help_list.each do |a_help|
    a_help.save_to_file("help/%s.yml" % a_help.keyword) # done and done.
  end
end

# Loads all help files
def load_helps
  log :debug, "Load_helps: getting all help files."

  hfiles = File.join("help", "*.yml")

  Dir.glob(hfiles).each do |a_file|
    help = Help.new()
    help.load_from_file(a_file) # loads each help file.
    help.text.gsub!(/\n/, "\r\n")
    $help_list << help
    case help.keyword
    when "GREETING" 
      $greeting = help.text
      log :debug, "Greeting loaded."
    when "MOTD"
      $motd = help.text
      log :debug, "MOTD loaded."
    end

  end    
end



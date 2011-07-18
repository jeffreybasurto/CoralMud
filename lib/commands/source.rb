class Player
  def cmd_source c, arg
    str = ""
    if !File.exist?("lib/commands/#{arg}.rb")
      return
    end
    f = File.open("lib/commands/#{arg}.rb")

    f.each_line do |l|
      str << l
    end
    text_to_player CodeRay.scan(str, :ruby).term
  end
end

class Player
  def cmd_mail cte, *args
    targets = args[0]
    txt = args[1]

    if targets == "list"
      self.messages.each do |msg|
        view msg.to_s
        msg.destroy!
      end
      return
    end


    m = Message.new 
    m.from = self.id
    m.text = txt
   
    targets.each do |target|
      target.messages << m
      view "Message sent to #{target.name}." + ENDL
      target.save
    end
    
  end
end


class Player
  def cmd_reply tab, arg
    if arg.empty?
      view "Reply with what?" + ENDL
      return
    end

    if @reply_to == nil 
      view "You cannot reply." + ENDL
      return
    end

    someone = @reply_to.get_player
    if !someone
      @reply_to = nil
      view "They already seem to be gone." + ENDL
      return
    end
    
    someone.reply_to = self.name

    someone.view "#R#{someone.peek(self)} tells you, '#{arg}'" + ENDL
    self.view "#RYou tell #{peek(someone)}, '#{arg}'" + ENDL
  end
end

class Player
  def cmd_tell table_entry, target, message
    case target
    when String
      if target.include?"@"
        to = target.split('@')

        if !to[0] || !to[1]
          text_to_player "That doesn't seem to be a valid target." + ENDL
          return
        end

        $imclock.synchronize do 
          $imcclient.private_send(@name.capitalize, to[0], to[1], message)
          text_to_player "#RYou tell #{target}, '#{message}'#n" + ENDL
        end
        return
      else
        self.peek "Doesn't appear to be a valid target." + ENDL
      end
    when Array
      target.each do |someone|
        someone.reply_to = self.name
        someone.view "#R#{someone.peek(self)} tells #{someone.peek(target-[someone] + ["you"])}, '#{message}'" + ENDL
      end  
      self.view "#RYou tell #{peek(target)}, '#{message}'" + ENDL
    else
      self.view "That's not quite ready yet."
    end
  end
end

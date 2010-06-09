class Player
  def cmd_filter tentry, arg
    @channel_flags.toggle(:language_filter)    
    if @channel_flags.is_set?(:language_filter)
      view "Our language filter will now be applied to your session." + ENDL
    else
      view "Our language filter will no longer be applied to your session." + ENDL
    end
  end
end

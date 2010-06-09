class Player
  def cmd_inews command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:inews]) == nil
        text_to_player "You will no longer observe the inews channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:inews] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the inews channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the inews channel." + ENDL
          @channel_flags.delete(:inews)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:inews", arg)
      end
    end
  end
end

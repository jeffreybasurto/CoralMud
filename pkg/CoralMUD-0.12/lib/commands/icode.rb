class Player
  def cmd_icode command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:icode]) == nil
        text_to_player "You will no longer observe the icode channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:icode] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the icode channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the icode channel." + ENDL
          @channel_flags.delete(:icode)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:icode", arg)
      end
    end
  end

end

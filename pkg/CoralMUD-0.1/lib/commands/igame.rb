class Player
  def cmd_igame command_table_entry, arg
    if arg == nil || arg.length == 0
      ### Toggle icode channel
      if (found = @channel_flags[:icode]) == nil
        text_to_player "You will no longer observe the igame channel." + ENDL
        ### Currently channel is on. Turn it off with user restriction.
        @channel_flags[:igame] = :channel_user_off
      else
        if found == :channel_mute_off
          text_to_player "You are not allowed to observe the igame channel." + ENDL
        else
          ### Currently the channel is off. Remove all restrictions.
          text_to_player "You can now observe the igame channel." + ENDL
          @channel_flags.delete(:igame)
        end
      end
    else
      $imclock.synchronize do
        $imcclient.channel_send("#{name.capitalize}", "Server02:igame", arg)
      end
    end
  end
end

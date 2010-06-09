class Player
  def cmd_iruby command_table_entry, arg
    $imclock.synchronize do
      $imcclient.channel_send("#{name.capitalize}", "Server02:iruby", arg)
    end
  end
end

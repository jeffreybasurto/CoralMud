class Player
  def cmd_iadmin command_table_entry, arg
    $imclock.synchronize do
      $imcclient.channel_send("#{name.capitalize}", "Server01:admin", arg, "ice-msg-p")
    end
  end
end

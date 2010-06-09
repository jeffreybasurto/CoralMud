class Player
  def cmd_snoop command_table_entry, arg


    if arg == "off"
    end

    arg.each do |person|
      if !person.socket
        next
      end
      

      person.socket.snoop = [] if !person.socket.snoop
      person.socket.snoop << WeakRef.new(self.socket)
    end
  end
end


Kernel::load("core/creation.rb")

# socket class to handle all connection and data IO. Except raw sockets.
module SocketData
  attr_accessor :player, :bust_prompt, :state, :port, :addr
  attr_accessor :mxp, :mccp
  attr_accessor :snoop

  # Called after our socket is fully initialized and ready to receive/send data.
  def post_init
    text_to_socket WILL_MXP    
    @state = :state_new_connection
    @mxp = false # MXP defaults to off.
    @mccp = nil
    @player, @nanny, @network_parser = nil, nil, nil
    @input_queue = []
    @bust_prompt = false
    $dsock_list << self

    @port, @addr = Socket.unpack_sockaddr_in(get_peername)
    log :info, "-- #{@addr}:#{@port} connected to CoralMUD!"
    assign_nanny
    assign_network_parser
  end

  ### Permanently assigns a parser to this socket.
  def assign_network_parser

    @network_parser = Fiber.new do
      mode = :data

      arr = []
      buffer = ""
      loop do ### loops forever while the socket exists.
        data = Fiber.yield arr
        arr = []
        ### process data and place it into arr
        while !data.empty?
          c = data.slice!(0)

          ### examine c for telnet escape.
          if c.ord == IAC
            seq = "" + c
            c = data.slice!(0)

            if c.ord == DO || c.ord == DONT
              seq = seq + c
              c = data.slice!(0)
              seq = seq + c + "\0" 
            end

            arr << seq
            next
          elsif c.ord == "\n"[0].ord
            buffer.strip!
            if !buffer.empty?
              arr << buffer 
            end
            buffer = ""
            next
          end

          buffer << c
        end
      end
    end
    @network_parser.resume
  end

  # Called any time data is received from a connected socket.
  def receive_data data
    if @state == :state_playing
      @bust_prompt = true
      $last_sent = '\n'
    end

    data = "\n" if data == nil
    data.gsub!(/\r\n|\n\r|\r|\n/,"\n")
    data = "\n" if data.empty?

    # separates telnet sequence from main data stream.  Returns the telnet sequences in their own string in the queue.
    a = @network_parser.resume data

    a.each do |d|
      data.gsub!(/\n/, "")
      if d.length == 0
        a.delete d
      end
    end 
 
    a << "" if a.empty?

    a.each do |d|
      @input_queue.push d
    end
 
    ## Ok, check we need to shift a command off the top.
    while !@input_queue.empty?
      comm = @input_queue.shift
      
      return if comm == nil 

      #  next if comm.length == 0
      if comm.length != 0 && comm[0].ord == IAC
        # let's see if it matches one we know of.
        do_mxp = DO_MXP 
        dont_mxp = DONT_MXP
        do_mccp = DO_MCCP
        dont_mccp = DONT_MCCP  

        if do_mccp == comm
          log :debug, "telnet do mccp sequence detected."
#          mccp_initialize(self)
        end
        if do_mxp == comm
          mxp_initialize(self)
          log :debug, "telnet do mxp sequence detected."
        end     
        log :debug, "telnet sequence detected."
        next ### it's a telnet sequence
      end
      case @state
        when :state_new_connection
          if @nanny.alive?
            if (@nanny.resume comm.downcase) == true
              text_to_socket "Closing connection." + ENDL
              close_connection
              return
            end
          end
        when :state_playing
          
          handle_cmd_input comm
        else
          log :error, "Socket in bad state."
      end
    end
  end

  ### Actually handles the input.
  def handle_cmd_input arg
    comm = ""
    dPlayer = @player
    return if dPlayer == nil

    one_arg(arg, comm, true)
    return if comm.empty?

    if @snoop
      @snoop.each do |sock|
        sock.send_data("(Snoop) #{arg}" + ENDL) if sock.weakref_alive?
      end
    end

    how_many = nil
    begin 
      how_many = Integer(comm)
      # also pull the real command
      one_arg! arg, comm, true
      one_arg! arg, comm, false
      return if comm.empty?
    rescue 
      one_arg! arg, comm, false
      how_many = 1
    end

    begin
      # execute it this many times in a row.
      how_many.times do 
        dPlayer.execute_command(comm, arg)
      end
    rescue Exception=>e
      dPlayer.view "Command failed." + ENDL
      log_exception e
    end
  end

  def text_to_socket txt    
    # neccessary to 
    $last_sent = txt[-1]

    if @mxp == true
      txt.convert_mxp!
      txt.finalize_mxp!
    else
      # strip out anything between \x03 and \x04 and anything between \x05 and ;
      txt.strip_mxp!
    end

    txt = render_color(txt)

    if @snoop
      @snoop.each do |sock|
        sock.send_data(txt) if sock.weakref_alive?
      end
    end
    send_data(txt)
    if @state == :state_playing
      @bust_prompt = true
    end
    return true
  rescue Exception
    return false
  end
  # Closes the connection for a single socket.
  def unbind
    $dsock_list.delete self

    log :info, "-- #{@player}:#{@addr}:#{@port} disconnected from CoralMUD!"

    if @player
      @player.socket = nil if @player.socket == self

      if @player.in_room
        @player.in_room.display([:visual, "other.can_see?(actor)"], @player, [@player], "<%=other.peek(actor)%> has lost their link.")
      end
    end

  end
end


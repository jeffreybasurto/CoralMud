############################################################################
### FRuby Client 1.0 by Retnur
### A big thanks goes out to Kiasyn.
############################################################################
# Copyright (c) 2009, Jeffrey Heath Basurto <bigng22@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
############################################################################

### A list of all known IMC channels.
$imc_channel_list = {:icode=>["Server02:icode", "#R"], 
                     :iruby=>["Server02:iRuby", "#R"],
                     :igame=>["Server02:igame", "#G"], 
                     :ichat=>["Server01:ichat", "#P"],
                     :inews=>["Server02:inews", "#W"],
                     :imudnews=>["Server02:imudnews", "#Y"],
                     :ibuild=>["Server01:ibuild", "#r"],
                     :imusic=>["Server02:imusic", "#p"],
                     :admin=>["Server01:admin", "#w"]}


### String extensions 
###
class String
  def encapsulate
    s = self
    s = s.reverse
    s.concat '"'
    s = s.reverse
    s.concat '"'
    return s
  end
end




### Net::Telnet extensions
###
class Net::Telnet
    def waitfor(options) # :yield: recvdata
      time_out = @options["Timeout"]
      waittime = @options["Waittime"]

      if options.kind_of?(Hash)
        prompt   = if options.has_key?("Match")
                     options["Match"]
                   elsif options.has_key?("Prompt")
                     options["Prompt"]
                   elsif options.has_key?("String")
                     Regexp.new( Regexp.quote(options["String"]) )
                   end
        time_out = options["Timeout"]  if options.has_key?("Timeout")
        waittime = options["Waittime"] if options.has_key?("Waittime")
      else
        prompt = options
      end

      if time_out == false
        time_out = nil
      end

      line = ''
      buf = ''
      rest = ''
      until(not IO::select([@sock], nil, nil, waittime))
        unless IO::select([@sock], nil, nil, time_out)
          raise TimeoutError, "timed out while waiting for more data"
        end
        begin
          c = @sock.readpartial(1024 * 1024)
          @dumplog.log_dump('<', c) if @options.has_key?("Dump_log")
          if @options["Telnetmode"]
            c = rest + c
            if Integer(c.rindex(/#{IAC}#{SE}/no)) <
               Integer(c.rindex(/#{IAC}#{SB}/no))
              buf = preprocess(c[0 ... c.rindex(/#{IAC}#{SB}/no)])
              rest = c[c.rindex(/#{IAC}#{SB}/no) .. -1]
            elsif pt = c.rindex(/#{IAC}[^#{IAC}#{AO}#{AYT}#{DM}#{IP}#{NOP}]?\z/no) ||
                       c.rindex(/\r\z/no)
              buf = preprocess(c[0 ... pt])
              rest = c[pt .. -1]
            else
              buf = preprocess(c)
              rest = ''
            end
         else
           # Not Telnetmode.
           #
           # We cannot use preprocess() on this data, because that
           # method makes some Telnetmode-specific assumptions.
           buf = rest + c
           rest = ''
           unless @options["Binmode"]
             if pt = buf.rindex(/\r\z/no)
               buf = buf[0 ... pt]
               rest = buf[pt .. -1]
             end
             buf.gsub!(/#{EOL}/no, "\n")
           end
          end
          @log.print(buf) if @options.has_key?("Output_log")
          line += buf
          yield buf if block_given?
        rescue EOFError # End of file reached
          if line == ''
            line = nil
            yield nil if block_given?
          end
          break
        end
      end
      line
    end
end
### Look for usage below for examples.
### You should only need to instantiate this a single time.
class IMCclient
  ### This is called when IMCclient is instantiated.
  def initialize(name, pw)
    @connection = Net::Telnet::new( "Host" => "74.207.247.83",
                                    "Port" => 5000,
                                    "Telnetmode" => false,
                                    "Prompt" => /\n/)
    @pw = pw
    # Start authenticating. Will autosetup if IMC server does not have configuration.
    @connection.puts "PW #{name} #{pw} version=2 autosetup #{pw}2"
    # Set the sequence, which is a number associated with each packet
    @sequence = Time.now.to_i
    @myname = name
    @chat_log = []
    @@client_thread = Thread.new do
      loop do
        $imclock.synchronize do
          $imcclient.accept_data
        end
        sleep 0.2
      end
    end
  end
 
  ### call this in some event.  It really should called at least twice a second.
  ### This continually checks for incoming packets
  def accept_data 
    # empty string
    s= ""
    ### read from connection and put it in s
    begin
      @connection.waitfor({"Timeout"=>false, "Waittime"=>0})  do |c|
        break if c == nil
        s << c
      end
    rescue
      #$imcclient = nil
    end
    ### If s is empty we return.
    return if s.chomp.empty? 
    ### Search for new packets line by line and process.
    while ( (line = s.pop_line) != nil )
      ### Does something with each line. Probably a chat message.
      handle_server_input line
    end
  end
 
  ### Handles raw input
  ### Directs towards packets.
  def handle_server_input(s)
    case s.strip
      #On initial client connection:
      #SERVER Sends: autosetup <servername> accept <networkname> (SHA256-SET)
    when /^autosetup (\S+) accept (\S+)$/
      log :debug, "Autosetup complete. Connected to #{$1} on network #{$2}"
    when /^PW Server\d+ #{@pw} version=2 (\S+)$/i
      log :debug, "IMC Authentication complete"
      send_isalive
    when /^(\S+) \d+ \S+ (\S+) (\S+)$/i
      handle_packet( $1, $2, $3 )
    when /^(\S+) \d+ \S+ (\S+) (\S+) (.*)$/i
      handle_packet( $1, $2, $3, $4 )
    else
      # meh
    end
    #You@YourMUD 1234567890 YourMUD tell Dude@SomeMUD text="Having fun?"
  end
  ### Processes all packets and directs it.
  def handle_packet( sender, type, target, data=nil )
    if data != nil and data.is_a?( String ) then
      new_data = Hash.new

      data.strip!
      data = StringScanner.new(data) 
      while !data.eos?
        key = data.scan(/\w+/) ### grab a key
        data.skip(/=/) ### skip the =
        if data.peek(1).eql?('"')
          val = data.scan(/"([^"\\]*(\\.[^"\\]*)*)"/)
          val.slice!(0)
          val.slice!(-1)
        else
          val = ""
          while (!data.eos? && !data.peek(1).eql?(' '))
            val << data.getch
          end
        end
        data.skip(/\s+/)
        new_data[key] = val
      end
      data = new_data
    end
  #  return if sender.include?("@#{@myname}")
  #  return if data != nil and data.include? 'sender' and data['sender'].include? "@#{@myname}"
    #You@YourMUD 1234567890 YourMUD tell Dude@SomeMUD text="Having fun?"
    case type
    when "keepalive-request"
      send_isalive
    when "tell"
      $dplayer_list.each do |dplayer|
        if dplayer.name.downcase == (target.split('@')[0]).downcase
          dplayer.text_to_player("#R#{sender} tells you, '" + data['text'] + "#R'#n" + ENDL)
          break
        end
        $imcclient.private_send("CM", *sender.split('@'), "#{target.split('@')[0]} was not found on CoralMUD.")
      end
    when "ice-msg-b"
      cn = data['channel'].split(":")
      cn[1].strip!
      $dplayer_list.each do |dPlayer|      
        if dPlayer.channel_flags[cn[1].to_sym] != nil
          next
        end

        chan_data = $imc_channel_list[cn[1].to_sym]
        if chan_data != nil
          col = chan_data[1]
        else
          col = "#D"
        end
        data['text'].gsub!('#', '##')
        data['text'].gsub!('\"', '"')
        dPlayer.text_to_player "#{col}(#{cn[1]}) #{sender} says, '#{data['text']}'" + ENDL
        log_chat  Time.now.strftime("#{col}[%I:%M%p]"), cn[1], "(#{cn[1]}) #{sender} says, '#{data['text']}'\r\n"
      end
    when "ice-msg-p"
      cn = data['channel'].split(":")
      $dplayer_list.each do |dPlayer|
        if dPlayer.channel_flags[cn[1].to_sym] != nil
          next
        end
        dPlayer.text_to_player "#p(#{cn[1]}) #{data['realfrom']} says, '#{data['text']}'#n" + ENDL
      end
    when "ice-msg-r"
      cn = data['channel'].split(":")
      $dplayer_list.each do |dPlayer|
        if dPlayer.channel_flags[cn[1].to_sym] != nil
          next
        end
        dPlayer.text_to_player "#p(#{cn[1]}) #{data['realfrom']} says, '#{data['text']}'#n" + ENDL
      end
    end
  end

  ### Sends a packet in the right format.
  def packet_send( sender, type, target, destination, data)
    data_out = ""
    if data.is_a?( Hash ) then
      hash = data.to_hash
      hash.each do |k, v|
        v.to_s.gsub!('"', '\"')
        if v.to_s.include? " " then
          v = v.encapsulate
        end
        data_out.concat "#{k}=#{v} "
      end
    end
    packet = "#{sender}@#{@myname} #{@sequence} #{@myname} #{type} #{target}@#{destination} #{data_out}"
    @sequence += 1
    @connection.puts packet
  end

  def private_send(sender, target, destination, message, type='tell')
    packet_send(sender, type, target, destination, {:text=>message})
  end

  ### This formats for a specific channel.
  ### channel_send "Retnur", Server01:ichat, "example string"
  def channel_send( sender, channel, message, type='ice-msg-b')
    packet_send( sender, type, '*', '*', {:channel => channel, :text => message, :emote => 0, :echo => 1 })
  end

  ### Sends info to IMC server about mud.
  ### host is your muds address, port is its port.  url is your web site.
  ### This isn't required.
  def send_isalive
    packet_send( "*", "is-alive", "*", "*", { :versionid => "CoralMud Client1.0", :url => "", :host => "", :port => 0} )
  end

  ### Shut the IMCclient down.
  def shutdown
    log :debug, "IMC Connection closed."
    @connection.close
  end

  # keeps a chatlog of the last 50 events. Not per channel.
  def log_chat time, chan, string
    @chat_log << [time, chan, string]
    #@chat_log.delete @chat_log[-1] if @chat_log.length > 50
  end

  def ret_log chan 
    s = "_#{chan}_Logs_________________________________________________________\r\n"
    @chat_log.each_index do |i|
      if @chat_log[i][1].include? chan
        s << (@chat_log[i][0] + @chat_log[i][2])    
      end
    end
    return s
  end
end



# ### Beginning of actual execution.
# ### You ned to change this name and password.
# ### create our client and a lock for it.
# begin
#   opts = YAML::load( File.open( 'imc.config' ) )
#   puts opts
#   $imcclient = IMCclient.new(opts[:name], opts[:pass])
#   $imclock = Mutex.new
# rescue Exception => e

#   puts e
#   puts "You must add an imc.config files in your root directory."
#   puts "It should looke like this:"
#   puts "---"
#   puts "name: yourmud"
#   puts "pass: yourpass"
#   exit
#   # It will authenticate it fine once the file is added. 
# # ---
# # name: yourmud
# # pass: yourpass

# end

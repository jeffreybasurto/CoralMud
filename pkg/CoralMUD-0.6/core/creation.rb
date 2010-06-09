
require 'core/creation_data'

module SocketData
  ### Attaches a nanny to a socket.  It only exists while in creation.
  def assign_nanny
    @nanny = Fiber.new do
      ### enter login menu
      text_to_socket $greeting
      text_to_socket "#nWhat is your name? "

      ### yield and on next call set arg
      while !check_name((narg = Fiber.yield false).capitalize)
        text_to_socket "That's not a valid name.  What is your name?" + ENDL
        log :info, "-- #{@addr}:#{@port}: Invalid name in character creation."
      end

      ### ensures the name is capital.
      narg.capitalize!
      log :info, "-- #{@addr}:#{@port}: #{narg} is trying to connect."
      ### valid name found. We should create their player now.
      text_to_socket "Thank you." + ENDL


      if File.exists?("players/#{narg.downcase.capitalize}.yml") == false
      ### If a new player is not found we need to create a new one.
        log :info, "-- #{@addr}:#{@port}: #{narg}:  New Character."
        @player = Player.new

        @player.name = narg.dup
        # prepare for next step

        text_to_socket DONT_ECHO
        ### This will loop until both passwords match.
        loop do
          text_to_socket "Please enter a new password: "
          while !check_pass((parg = Fiber.yield false))
            ### We could also explain here what constitutes a valid password.
            text_to_socket "That's not a valid password.  What is your new password#{ENDL}: "
          end

          ### Ask them to reenter their password.
          text_to_socket "Thank you.  Can you please verify the password?" + ENDL

          p2arg = Fiber.yield false

          if parg.eql? p2arg
            text_to_socket "Passwords match." + ENDL
            @player.password = parg.dup
            break
          else
            text_to_socket "Passwords do not match." + ENDL
          end
        end
        text_to_socket DO_ECHO

        text_to_socket "Entering character creation." + ENDL
        text_to_socket "Enter any key to continue . . ." + ENDL
        Fiber.yield false

        creation_menu = enter_creation_menu()
        creation_menu.resume "" # Start menu system.
        ### enter creation menu.
        loop do
          # Break after the creation menu is no longer active.
          if !creation_menu.alive?
            break
          end
          if creation_menu.resume(Fiber.yield false)
            break
          end
        end
        ### End character creation loop
        ###
        ###
        log :info, "-- #{@addr}:#{@port}: #{@player.name} successfully created."
      else
        log :info, "-- #{@addr}:#{@port}: #{narg} player file found." 
        @player = Player.load_pfile(narg)
        ### old player found.
        ### do this until passwords match.
        attempt = 0
        text_to_socket DONT_ECHO
        begin
          log :info, "-- #{@addr}:#{@port}: #{@player.name} password incorrect." if attempt > 0
          attempt += 1
          if attempt > 3
            log :info, "-- #{@ip}: #{@port} has been disconnected for 3 failed attempts for #{@player.name}."
            Fiber.yield true
          end
          text_to_socket "Password: "
          parg = Fiber.yield false
        end while parg != @player.password
        text_to_socket DO_ECHO
        text_to_socket "Password matches.  Thank you.\r\n"

        if (@player = check_reconnect(@player.name)) != nil
          @state = :state_playing
          log :info, "-- #{@addr}:#{@port}: #{@player} has reconnected."
          text_to_socket "You take over a body already in use.\r\n"
        elsif (@player = Player.load_pfile(narg)) == nil
          text_to_socket "ERROR: Your pfile is missing!\r\n"
          log :info, "-- #{narg}'s pfile was missing after originally found."
          Fiber.yield true
        end
      end

      @state = :state_playing
      log :info, "-- #{@player.name} has entered the game."
      @player.to_room(ROOM_ON_CREATE)
      text_to_socket $motd
      @player.socket = self
      $dplayer_list << @player if !$dplayer_list.include? @player
      @player.execute_command("look");
      @player.save_pfile
      false
    end

    @nanny.resume ""
  end
















  def enter_creation_menu 
    return Fiber.new do 
      ### dump the menu options 
      ### generate the menu each pass.
      length = 79
      ### CREATION TABLE
      ### To add more creation categories add to this table.
      ccmenu =[
             {:tag=>'1', :desc=>"race",          :data=>CCDEFAULT_DATA, :count=>1, :table=>$ccmenu_element[:menu_race],:question=>"Please choose a race."},
             {:tag=>'2', :desc=>"class",         :data=>CCDEFAULT_DATA, :count=>1, :table=>$ccmenu_element[:menu_class],:question=>"Please choose a class."},
             {:tag=>'3', :desc=>"sign",          :data=>CCDEFAULT_DATA, :count=>1, :table=>$ccmenu_element[:menu_signs],:question=>"Under which sign were you born?"},
             {:tag=>'4', :desc=>"traits",        :data=>CCDEFAULT_DATA, :count=>3, :table=>$ccmenu_element[:menu_traits],:question=>"Please pick 3 traits."},
             {:data=>"".ljust(length-2, "-")},                      ### This line has no way of accessing it but the data still will be printed.
             {:tag=>'q', :desc=>"quit"}]
      ### At this point we should enter our menu driven system. 

      loop do
        buf =  "#w" + "#W________________________".ljust(length, '_') + ENDL
        buf << "#w" + "#W___#BCHARACTER CREATION#W___".ljust(length, '_') + ENDL
        ccmenu.each do |main_menu_option|
          t = ""
          ### Each m is a map
          t << "%3s)" % main_menu_option[:tag] + " " if main_menu_option[:tag] != nil
          t << main_menu_option[:desc].o_ljust(18) + " " if main_menu_option[:desc] != nil

          ### Depending on the type of data we may do something different with it.
          ### Type String:  Print it
          ### Type Array: Print on each line.
          if main_menu_option[:data] == nil
            buf << "#W=" + t.o_ljust(length-2) + "#W=" + ENDL
          elsif main_menu_option[:data].is_a? String
            tmp = main_menu_option[:data]
            if tmp.eql? CCDEFAULT_DATA
              t.insert(0, "#R")
            else
              t.insert(0, "#W")
            end
            t << tmp
            buf << "#W=" + t.ljust(length-2) + "#W=" + ENDL
          elsif main_menu_option[:data].is_a? Array
            datum = main_menu_option[:data]
            if datum.length == 1
              t << main_menu_option[:table][datum[0]][:name]
              buf << "#W=" + t.ljust(length-2) + "#W=" + ENDL
              next
            end
            t.gsub!(" ", "_")
            buf << "#W=" + "#W" + t.o_ljust(length-2, '_') + "#W=" + ENDL
            datum.each do |e|
              ### For each element in the array dump an explaination on its own line.
              tmp = main_menu_option[:table][e][:desc].dup
              tmp_n = main_menu_option[:table][e][:name]
              ccc = 0
              while !tmp.empty?
                if ccc == 0
                  buf << "#W= " + " #C#{'%-20s' % tmp_n}#C " + tmp.pop_some(length-4-22).ljust(length-4-22) + "#W =" + ENDL
                else
                  buf << "#W= " + "#C" + tmp.pop_some(length-4).ljust(length-4) + "#W =" + ENDL
                end
                ccc += 1
              end
            end
          end
        end
        buf << "#W"+ "==[#{Time.now.strftime("#R%I:%M%p#w")}#W]==".rjust(length, '=') + ENDL
        text_to_socket buf
        text_to_socket "Please make a selection:"

        # receive input for menu.
        argselect = Fiber.yield false

        ### parse the options and see if any match
        menufound = nil
        ccmenu.each do |v|
          next if v[:tag] == nil

          if argselect.eql? v[:tag].downcase
            ### And this is ugly because each field has a totally different check against the parameter.
            ### We're trying to streamline it based on how many options and the table of options.
            menufound = v
          end
        end
        if menufound == nil ### This means the user option was not found on the menu.
          text_to_socket "That is not a valid option." + ENDL
        else
          ### We found The key
          if menufound[:tag].eql? "q"
            ### This is the quit option.  Special case for this since it is for breaking the loop.
            ### Check to see if every condition is met.
            all_cond_met = true
            ccmenu.each do |check_each|
              next if check_each[:tag] == nil || check_each[:data] == nil

              if !check_each[:data].is_a?(Array)
                all_cond_met = false
                break
              end
              if check_each[:data].length != check_each[:count]
                all_cond_met = false
                break
              end
            end
            if !all_cond_met
              text_to_socket "All conditions are not met." + ENDL
              text_to_socket "Enter any key to continue . . ." + ENDL
              Fiber.yield false
            else
              text_to_socket "Thank you.  All conditions are met." + ENDL
              text_to_socket "Enter any key to continue . . ." + ENDL
              Fiber.yield false
              ### convert the data we mined into data on the Player structure.
              ccmenu.each do |elem|
                case elem[:desc]
                  when "race" then    @player.race = elem[:data][0]
                  when "class" then   @player.clas = elem[:data][0]
                  when "traits" then  @player.traits = elem[:data].dup
                  when "sign" then    @player.sign =  elem[:data][0]
                end
              end
              break
            end
          else ### Otherwise figure out which table we're using and let them select a certain number of options.
            ### First clear the data
            menufound[:data] = []
            print_menu_options(self, menufound)
            loop do ### print the current menu and its selections.  
              if menufound[:data].length != 0
                text_to_socket "#W".center(length, '_') + ENDL
                text_to_socket "#W__#BYOUR #{menufound[:desc].upcase}#W".ljust(length, '_') + ENDL
                text_to_socket "= Empty".ljust(length-2) + " =" + ENDL if menufound.empty?
                menufound[:data].each do |mmm|
                  text_to_socket "= " + menufound[:table][mmm][:name].ljust(length-4) + " =" + ENDL
                end
                text_to_socket "#W= " + "".center(length-4, '=') + " =#n" + ENDL
              end
              break if menufound[:data].count >= menufound[:count]
              text_to_socket menufound[:question] + ENDL
              text_to_socket ">>>"
              argselect = Fiber.yield false ### Accept input

              ### Match argselect against menufound[:table] values
              mfound = false
              menufound[:table].each do |k, v|
                if argselect.eql?(v[:name].downcase) && !menufound[:data].include?(k)
                  ### we found a valid object. We should add the key to the data.
                  menufound[:data] << k
                  mfound = true
                  break
                end
              end
              next if mfound == true
              text_to_socket "That is not a valid selection." + ENDL
              text_to_socket "Enter any key to continue . . ." + ENDL
              Fiber.yield false
              print_menu_options(self, menufound)
            end
          end
        end
      end ### MENU LOOP
    end ### Entire thing in a fiber returned.
  end
end



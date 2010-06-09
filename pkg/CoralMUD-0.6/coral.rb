#!/usr/local/bin/ruby
=begin
 CoralMUD prerelease candidate by Jeffrey Heath Basurto                   
                                 AKA Retnur AKA Runter                    

 Copyright (c) 2009, Jeffrey Heath Basurto <bigng22@gmail.com>

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
=end

### Include files
%w[zlib log4r test/unit weakref fcntl singleton eventmachine yaml fiber pp net/telnet.rb strscan core/socketengine thread].each { |lib| require lib }

include Log4r

##############################################################
# All global variables for the CoralMUD is below this point. #
##############################################################
$mudmachine = nil        # instance of mud running.
$dsock_list = []         # Active sockets. Generally managed.
$dplayer_list = []       # the player list of active players
$mo_list =  []           # A list of all mo mixed'in objects.  This includes players, mobiles, and equipment.
$shut_down = false       # used for shutdown
$help_list = []        # Help files.
$tabCmd = []           # the command table
$greeting = ""         # the welcome greeting
$motd = ""             # the MOTD help file
$last_sent = nil
$load_time = nil
$area_list = []        # list of areas. Internally managed, really.
$room_save_list = []   # List of rooms that need to be saved on next save event.
$room_list = []        # The core list of rooms in the game.

##############################################################
# load_library is the function called to attempt to reload   #
#   Any changed library files. (With a few exclusions)       #
##############################################################
### Loads these files dynamically from /lib in this order.

Kernel::load("lib/logs.rb")  # we need logging facilities immediately.
log :info, "Logging enabled.   Loading logs.rb."

$load_library_list = [
                      ["utils.rb",      true], ### Utility functions. Only loaded once.
                      ["constants.rb",  true], ### constants only loaded once.
                      ["class_property.rb", true],    ###  mix-in modules for classes.
                      ["tags.rb",     false], ### support for tag ID system.
                      ["editor/editors.rb",    true], ### Code for metaprogramming editors. 
                      ["editor/editor.strings.rb", false],
                      ["editor/editor.rooms.rb", false],
                      ["editor/editor.exits.rb", false],
                      ["mxp.rb",        true], ### MXP support and definitions. 
                      ["mccp.rb",       true], # MCCP support and definitions.
                      ### Below here is loaded every time.
                      ["flags.rb", false],
                      ["damage.rb", false],
                      ["areas.rb", false],
                      ["event.rb", false],            ### Triggers and autonomy.
                      ["automap/automap.rb", false], ### Automapper support for rooms vers 2.
                      ["cities.grids.rb", false],     ### Virtual space for rooms
                      ["cities.olc.rb", false],       ### CityRoom specific OLC
                      ["cities.rb", false],           ### CityRoom structure
                      ["help.rb", false],             ### Helpfile support
                      ["imcruby.rb", false],          ### imcruby client
                      ["player.rb", false],           ### player structure
                      ["player.commands.rb", false],  ### player command & wizard functions
                      ["random.rb", false],           ### rand extensions
                      ["items.rb", false],
                      ["spells.rb", false]]

### Only loads everything when initial is true
def load_library initial=false
  loaded = false
  $load_library_list.each do |entry|
    next if not initial and entry[1]
    if (File.stat("lib/" + entry[0]).mtime.to_i rescue 0) > $load_time.to_i
      log :info, "Loading #{entry[0]}"
      Kernel::load("lib/" + entry[0])
      loaded = true
    end
  end
  if loaded
    $load_time = Time.now
  end
end

# CoralMUD entry of code. Execution starts here.
#
if __FILE__ == $0
  # core loop. Only comes back when EventMachine gives up control.
  # If shut_down is not set then we will restart the mud in place.
  while !$shut_down
    load_library true
    load_helps

    Zone.load_zones
    Room.load_rooms # loads all rooms.

    # note that we are booting up
    log :info, "Starting server."

    # start the server.
    # This loop will not exit until a shutdown or reboot occurs.
    EventMachine::run do
      ### There is no real purpose for this but it is nice when rebooting. You could make the timer any amount.
      ### Adds a non-reoccuring timer for 1 seconds.  After 1 seconds it boots up the MUD.
      ### SocketData is the structure for connections.
      ### MUDPORT can be changed in lib/const.rb
      EventMachine::add_timer(1) do
        begin
          $mudmachine = EventMachine::start_server "0.0.0.0", MUDPORT, SocketData
          log :info, "CoralMUD is now up on port #{MUDPORT}."
        rescue Exception
          log :error, "CoralMUD boot failure."
        end 
      end

      EventMachine::add_periodic_timer(120) do
        log :info, "tick!!!"
        ### Save pfiles automatically every 2 minute.
        ### Keep in mind we want to make sure everyone is saved at the same time.
        ### It prevents possible exploits with duping items in the future with crashes.
        $dplayer_list.each do |ch|
          ch.save_pfile
          ch.text_to_player "Tick!!!" + ENDL
        end
      end


      ### Start an event for every second.
      EventMachine::add_periodic_timer(1) do
        ### Only purpose of this function is to reload our lib files autonomously.
        ### Keep in mind that some of the file dependancies in lib won't be loaded here.
        ### They are excluded from this function.
        ### It's also called no fewer than once per second.
        load_library
      end
      
      ## This is our gameloop.
      EventMachine::add_periodic_timer(0.05) do
        if $shut_down == true
          EM::next_tick do
            EM::stop_server $mudmachine
            $mudmachine = nil
            EM::stop_event_loop
          end
        end
        heartbeat     # this will be called no fewer than 10 times a second
      end

    end # EventMachine::run block
  end

  # Logs the program exiting.
  log :info, "Program closed."
  exit 0
end


=begin
 CoralMUD prerelease candidate by Jeffrey Heath Basurto                   
                                 AKA Retnur AKA Runter                    

 Copyright (c) 2009-2010, Jeffrey Heath Basurto <bigng22@gmail.com>

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
%w[erb weakref fcntl singleton yaml fiber pp net/telnet.rb strscan thread].each { |lib| require lib }

require 'bundler/setup'
Bundler.require

load "core/database.rb"
load "core/socketengine.rb"

Linguistics::use( :en )
include Log4r

##############################################################
# All global variables for the CoralMUD is below this point. #
##############################################################
$mudmachine = true        # instance of mud running.
$dsock_list = []         # Active sockets. Generally managed.
$dplayer_list = []       # the player list of active players
$mo_list =  []           # A list of all mo mixed'in objects.  This includes players, mobiles, and equipment.
$shut_down = false       # used for shutdown
$reboot = false
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

$load_library_list = [["spellcheck.rb", false],
                      ["facade.rb",     true], # simple facade for hiding functionality.
                      ["query_list.rb", false], # used for querying lists with player input.
                      ["utils.rb",      true], ### Utility functions. Only loaded once.
                      ["word_processing.rb", true], 
                      ["constants.rb",  true], ### constants only loaded once.
                      ["damage.rb", true],
                      ["class_property.rb", true],    ###  mix-in modules for classes.
                      ["scripts.rb", true],
                      ["tags.rb",     false], ### support for tag ID system.
                      ["editor/editors.rb",    true], ### Code for metaprogramming editors. 
                      ["editor/editor.strings.rb", true],
                      ["editor/editor.rooms.rb", true],
                      ["editor/editor.exits.rb", true],
                      ["editor/editor.zones.rb", true],
                      ["editor/editor.npc.rb",  true],
                      ["editor/editor.items.rb", true],
                      ["editor/editor.socials.rb", true],
                      ["socials.rb", true],
                      ["mxp.rb",        true], ### MXP support and definitions. 
                      ["mccp.rb",       true], # MCCP support and definitions.
                      ### Below here is loaded every time.
                      ["mail.rb",  false],
                      ["flags.rb", false],
                      ["areas.rb", false],
                      ["security.rb", false],
                      ["resets.rb", false],
                      ["event.rb", false],            ### Triggers and autonomy.
                      ["automap/automap.rb", false], ### Automapper support for rooms vers 2.
                      ["cities.rb", false],           ### CityRoom structure
                      ["help.rb", false],             ### Helpfile support
                      ["imcruby.rb", false],          ### imcruby client
                      ["CMI/client.rb", false],
                      ["player.rb", false],           ### player structure
                      ["commands.rb", false],
                      ["editor/editor.player.rb", true],
                      ["random.rb", false],           ### rand extensions
                      ["npc.rb", false],
                      ["items/types.rb", false],
                      ["items/items.rb", false],
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

# governing body of the mud.
class Console
  def self.shutdown
    puts "Shutting game down."
    EM::next_tick do
      EM::stop_server $mudmachine
      $mudmachine = nil
      EM::stop_event_loop
    end
  end

  def self.reboot
    puts "Rebooting server."
    $dsock_list.each do |s|
      s.send_data("The game is rebooting.  Please come back in a few minutes." + ENDL)
    end
    EM::next_tick do
        EM::stop_server $mudmachine
        EM::stop_event_loop
        $mudmachine = true
    end
  end
end

# CoralMUD entry of code. Execution starts here.
#
if __FILE__ == $0
  $consolelock = Mutex.new

  console_thread = Thread.new do 
    loop do
      console_input = gets
      console_input.strip!
      next if console_input.empty?
      # Do something with console input. 

      if Console.respond_to?(console_input.to_sym)  
        Console.send(console_input.to_sym)
      else
        log :debug, "Console input not recoginized: #{console_input}"
      end
    end
  end

  
  # core loop. Only comes back when EventMachine gives up control.
  # If shut_down is not set then we will restart the mud in place.
  while $mudmachine
    load_library true
    load_helps

    Zone.load_zones # zones have to come first so the rooms have a valid namespace when they load.
    Social.load_socials

    log :info, "Upgrading database"
    DataMapper.auto_upgrade!


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
          $cmimachine = EventMachine::connect "localhost", 5000, Rclient
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
          ch.save_to_database
          ch.view "Tick!!!" + ENDL
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
        if $reboot == true
          Console.reboot
        end
        if $shut_down == true
          Console.shutdown
        end
        heartbeat     # this will be called no fewer than 10 times a second
      end

    end # EventMachine::run block
    if $mudmachine == true # reboot
      exec "ruby coral.rb"
    end
  end

  # Logs the program exiting.
  log :info, "Program closed."
  exit 0
end


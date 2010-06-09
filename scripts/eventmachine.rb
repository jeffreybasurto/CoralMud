require 'eventmachine'

CRAWL_LIST = [ #["eotmud.com", 4000], 
              ["throes.slayn.net", 1200],
              ["nimud.org", 5333]]

$times_crawled = 0

class Crawler < EventMachine::Connection
  def initialize(*args)
    super
  end
    
  def receive_data(data)
    # Do nothing with the data received.
  end
end
EventMachine::run {
  EventMachine::add_periodic_timer(120) {
    $times_crawled += 1
    print "Crawl number: #{$times_crawled}\n"
    print "Connection success to: "
    CRAWL_LIST.each do |c|
      print "#{c[0]}:#{c[1]} "
      EventMachine::connect c[0], c[1], Crawler
    end  
    print "\n"
  }
}


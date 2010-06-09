$quotes = [["Author Unknown", "Why does it take a minute to say hello and forever to say goodbye?"],
           ["George Lansdowne" ,"To die and part is a less evil; but to part and live, there, there is the torment."],
           ["Shakespeare","Farewell! God knows when we shall meet again."],
           ["Edward Young", "Fate ordains that dearest friends must part."],
           ["Alfred De Musset","The return makes one love the farewell."],
           ["Alan Alda","The best things said come last.  People will talk for hours saying nothing much and then linger at the door with words that come with a rush from the heart."],
           ["Lazurus Long","Great is the art of beginning, but greater is the art of ending."]]

class Player
  def cmd_quit command_table_entry, arg
    log :info, "#{@name} has left the game."
    found = $quotes.rand
    view "#R#{found[1]}"+ENDL
    view "#R~#{found[0]}"+ENDL
    view "#wAlas, all good things must come to an end." + ENDL
    save_to_database
    $dplayer_list.delete self
    from_room if in_room != nil
    self.recycle
    @socket.player = nil
    @socket.close_connection(true)
    @socket.recycle
  end
end

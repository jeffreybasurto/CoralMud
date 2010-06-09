class Player
  def cmd_test cte, arg
    view @id.to_s + ENDL
    self.save
    Player.all.each do |p|
      view "#{p.id} #{p.name}" + ENDL
    end    
  end
end

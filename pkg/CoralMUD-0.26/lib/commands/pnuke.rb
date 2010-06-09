class Player
  def cmd_pnuke cte, arg
    # delete all players except this one.
    Player.all.each do |p|
      p.destroy! if p != self
    end
  end
end


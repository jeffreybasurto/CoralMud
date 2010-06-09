class Player
  def cmd_gossip centry, arg
    communicate self, arg, :comm_global
  end
end

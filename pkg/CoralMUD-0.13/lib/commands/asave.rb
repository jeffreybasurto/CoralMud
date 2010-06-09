class Player
  def cmd_asave c_t_e, arg
    view "All areas saved." + ENDL
    Zone.save_all
    view "All socials saved." + ENDL
    Social.save_all
  end
end

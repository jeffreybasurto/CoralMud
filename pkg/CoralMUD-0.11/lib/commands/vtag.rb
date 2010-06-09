class Player
  # look up a tag of *any* object in the game space.
  def cmd_vtag cte, arg
    log :debug, arg
    tfound = Tag.find_any_obj arg

    if !tfound
      text_to_player "Nothing found." + ENDL
      return
    end

    tfound.each do |f|
      text_to_player "#{f} #{f.namespace}" + ENDL
    end
  end
end

class Player
  def cmd_spellcheck entry, word
    found = Spellcheck.suggestions(word)
    if found.empty?
      view "Seems correct." + ENDL
    else
      view "#nThis isn't correct." + ENDL
      view "#nCould you possibly mean #Y#{found[0]}#n?" + ENDL
      view "#nIf not, then #Y#{found[1..5]}#w are other possibilities."+ENDL
    end
  end
end

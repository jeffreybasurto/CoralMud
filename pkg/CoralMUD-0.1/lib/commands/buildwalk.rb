class Player
  def cmd_buildwalk command_table_entry, arg
    # either set build walk or remove it.
    if flags.include?("build walk")
      flags.delete("build walk")
      text_to_player "Build walk disabled." + ENDL
    else
      flags << "build walk"
      text_to_player "Build walk enabled." + ENDL
    end
  end
end

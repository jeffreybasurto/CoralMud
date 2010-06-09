class Player
  def cmd_debug command_table_entry, arg
    damage(1)
    text_to_player "#{health} #{damage}" + ENDL
    heal(1)
    text_to_player "#{health} #{damage}" + ENDL
  end
end

class Player
  def cmd_hit cmdtab, target
    target = [target].flatten
    t = target[0]

    dams = [(1..5), (5..20), (25..100)]
    dams.each do |range|
      t.take_damage(range.to_a.rand, self)
    end
  end
end

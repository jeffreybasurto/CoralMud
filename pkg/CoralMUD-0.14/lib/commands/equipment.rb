# if you don't want to show empty equipment just change this value to true.
OPTION_SHOW_ALL = true

# add to this table if there are other slots you wish to display.  
# Keep in mind that you can display slots that have no items defined for them.
# You can also not display slots where items could be although this use is
# dubious at best.
$locs_to_look_at = {:head=>["on head"],
                    :torso=>["on torso"],
                    :arms=>["on arms"],
                    :hands=>["on hands"],
                    :finger=>["on finger"],
                    :waist=>["around waist"],
                    :legs=>["on legs"], 
                    :feet=>["on feet"]}

class Player
  def cmd_equipment ctab, arg
    view "You are wearing #{"item".en.quantify(worn_items.count)}." + ENDL

    w = if @wearing then @wearing else {} end

    tarr = []
    $locs_to_look_at.each do |loc, val|
      f = w[loc]
      next if !OPTION_SHOW_ALL && !f
      tarr << [val[0].to_s + ":", if f then peek(f) else "-----" end]
    end

    # sizes to align the data at.  Probably overkill, but fun. :)
    loc_size = (tarr.collect {|v| v[0].length}).max
    eq_size = (tarr.collect {|v| v[1].length}).max

    tarr.each do |v|
      view "%#{loc_size}s   %s#{ENDL}" % [v[0], v[1].center(eq_size)]
    end
  end
end

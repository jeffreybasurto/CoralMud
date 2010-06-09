
class Player
  def cmd_vlist c,  arg
    if arg == nil
      found = [nil]
    elsif !(found = Tag.find_any_obj(arg))
      view "Namespace not found." + ENDL
      return
    end

    f = FormatGenerator.new 4, {:sep=>" ", :lf=>ENDL}

    Tag.search_namespace(found[0]) do |something|
      view something.to_s + f.resume
    end
    view f.end
    view "Total: " + f.count.to_s + ENDL
  end
end

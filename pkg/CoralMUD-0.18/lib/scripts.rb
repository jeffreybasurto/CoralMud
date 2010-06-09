
module ScriptEnvironment
  def run txt, b=binding()
    proc {
      txt.untaint
      $SAFE = 3
      begin
        b.eval(txt)
      rescue Exception=>e
        log :info, "Script failed."
        log_exception e, :info
      end
    }.call
  end
end


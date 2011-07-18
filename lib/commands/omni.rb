# gives player all permissions that invokes this command.  
# Once game is set up you probably don't want this available. :)
class Player
  def cmd_omni cte, arg
    @security = {:edit=>true, :global_editor_access=>true}
    view "You now have editor security.  To add access to commands try \"edit #{self.name}\" to edit your own pfile."
  end
end


class Social
  define_creatable
  define_editor :social_edit
  define_editor_field({:name=>"vtag", :filter=>:filt_to_tag, :type=>:vtag},
                      {:name=>"name"},
                      {:name=>"noarg"},
                      {:name=>"onoarg"},
                      {:name=>"found"},
                      {:name=>"ofound"},
                      {:name=>"tfound"},
                      {:name=>"auto"},
                      {:name=>"oauto"})

  def self.create ch
    social = self.new
    social.namespace = nil
    social.assign_tag Tag.gen_generic_tag(social), nil
    return social
  end
end

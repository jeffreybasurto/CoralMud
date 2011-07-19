### Character creation constants
CCDEFAULT_DATA = "Not set."

### At this point we should enter our menu driven system. 
$ccmenu_element ={:menu_race=>{:race_human=>{:name=>"human",
                                             :desc=>"Primary Attribute: Wisdom"},
                               :race_dwarf=>{:name=>"dwarf",
                                             :desc=>"Primary Attribute: Strength"},
                               :race_feline=>{:name=>"feline",
                                              :desc=>"Primary Attribute: Dexterity"},
                               :race_elf=>{:name=>"elf",
                                           :desc=>"Primary Attribute: Intellect"}
                              },

                  :menu_class=>{:class_warrior=>{:name=>"warrior",    :desc=>"tank"},
                                :class_thief=>{:name=>"thief",        :desc=>"melee dps"},
                                :class_mage=>{:name=>"mage",          :desc=>"range dps"},
                                :class_cleric=>{:name=>"cleric",      :desc=>"healer"}
                               },

                 :menu_traits=>{ :trait_hearty=>{:name=>"hearty",       :desc=>"+15% to health pool"},
                                 :trait_enchanted=>{:name=>"enchanted", :desc=>"+ 5% spell damage"},
                                 :trait_fleeting=>{:name=>"fleeting",   :desc=>"+ 8% evasion"},
                                 :trait_protected=>{:name=>"protected", :desc=>"+15% armor"},
                                 :trait_powerful=>{:name=>"powerful",   :desc=>"+ 5% to melee damage"},
                                 :trait_precise=>{:name=>"precise",     :desc=>"+ 8% melee accuracy"},
                                 :trait_learned=>{:name=>"learned",     :desc=>"+ 8% spell accuracy"},
                                 :trait_deft=>{:name=>"deft",           :desc=>"+ 3% critical strike chance"},
                                 :trait_destined=>{:name=>"destined",   :desc=>"+ 3% critical magic chance"}
                    },
                   :menu_signs=>{:sign_ram=>{:name=>"The Ram",            :desc=>"Stinky ram"},
                                 :sign_bull=>{:name=>"The Bull",          :desc=>"Stinky bull"},
                                 :sign_twins=>{:name=>"The Twins",        :desc=>"The twins"},
                                 :sign_crab=>{:name=>"The Crab",          :desc=>"I pinch"},
                                 :sign_lion=>{:name=>"The Lion",          :desc=>"Roar"},
                                 :sign_virgin=>{:name=>"The Virgin",      :desc=>"Davion"},
                                 :sign_scales=>{:name=>"the Scales",      :desc=>"Balance is justice"},
                                 :sign_scorpion=>{:name=>"The Scorpion",  :desc=>"Comedy TBA"},
                                 :sign_archer=>{:name=>"The Archer",      :desc=>"Elegarn"},
                                 :sign_capricorn=>{:name=>"The Capricorn",:desc=>"Most boring"},
                                 :sign_maiden=>{:name=>"The Maiden",      :desc=>"Sezen"},
                                 :sign_sea=>{:name=>"The Sea",            :desc=>"Moon Harbor"}
                    }
                  }

def print_menu_options(d, menufound)
  length = 79
  d.text_to_socket "#W".center(length, '_') + ENDL
  d.text_to_socket "#W__#B#{menufound[:desc].upcase}#W".ljust(length, '_') + ENDL
  menufound[:table].each do |k, v|
    tmp = v[:desc].dup
    tmp_n = v[:name]
    ccc = 0
    while !tmp.empty?
      if ccc == 0
        d.text_to_socket "#W= " + " #C#{'%-20s' % tmp_n}#C " + tmp.pop_some(length-4-22).ljust(length-4-22) + "#W =" + ENDL
      else
        d.text_to_socket "#W= " + "#C" + tmp.pop_some(length-4).ljust(length-4) + "#W =" + ENDL
      end
      ccc += 1
    end
  end
  d.text_to_socket "#W=".center(length, '=') + "#n" + ENDL
end


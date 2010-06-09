MXP_BEG = "\x03"  #  /* becomes < */
MXP_END = "\x04"  #  /* becomes > */
MXP_AMP = "\x05"  #  /* becomes & */

# constructs an MXP tag with < and > around it 
def mxptag arg
  return MXP_BEG + arg + MXP_END
end
alias mxp mxptag

ESC = "\x1B" # escape character

def mxpmode(arg) 
  return ESC + "[" + arg.to_s + "z"
end


# flags for show_list_to_char


$eItemNothing = 1
$eItemGet = 2
$eItemDrop = 3
$eItemBid = 4

def mxp_initialize d
  d.mxp = true # flips it on

  d.text_to_socket START_MXP
  d.text_to_socket mxpmode (6) # perm secure mode
  d.text_to_socket mxptag "!-- Set up MXP elements --"

  d.text_to_socket mxptag "!ELEMENT Ex '<send>' FLAG=RoomExit"
  
  d.text_to_socket mxptag "!ELEMENT rdesc '<p>' FLAG=RoomDesc"

  #/* Player tag (for who lists, tells etc.) */
  d.text_to_socket mxptag "!ELEMENT Player \"<send href='tell &#39;&name;&#39; ' " +
                          "hint='Send a message to &name;' prompt>\" " +
                          "ATT='name'" 
end

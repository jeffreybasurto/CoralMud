MUDPORT           = 4000                   # just set whatever port you want

# player levels
LEVEL_PLAYER         =  1   # Almost everyone is this level
LEVEL_IMM            =  51  # Any admin without shell access
LEVEL_ADMIN          =  55  # Any admin with shell access


# Class foward definitions.
Player = Class.new  # in case we need to extend it before it's opened for hte first time.
#


IAC = 255     # interpret as command:
WONT = 252     # I won't use option
WILL = 251     # I will use option
DO   = 253  # Do option
DONT = 254  # Dont do option
TELOPT_ECHO = 1   # echo

SB = 250  # Subnegotiation begin # IAC SB <option> <parameters> IAC SE
SE = 240  # Subnegotiation end

# 1 byte commands
GA    = 249  # Go Ahead
NOP   = 241  # No-op
BRK   = 243  # Break

# In RFC 854
AYT   = 246  # Are you there?
AO    = 245  # abort output
IP    = 244  # interrupt
EL    = 248  # erase current line
EC    = 247  # erase current character

DM    = 242  # data mark - sent to demarcate end of urgent commands

EOR   = 239 # end of record (transparent mode)
ABORT = 238 # Abort process
SUSP  = 237 # Suspend process
EOF   = 236 # End of file

# Options
BINARY         =   0 # Transmit Binary - RFC 856
ECHO           =   1 # Echo - RFC 857
RCP            =   2 # Reconnection
SGA            =   3 # Suppress Go Ahead - RFC 858
NAMS           =   4 # Approx Message Size Negotiation
STATUS         =   5 # Status - RFC 859
TM             =   6 # Timing Mark - RFC 860
RCTE           =   7 # Remote Controlled Trans and Echo - RFC 563, 726
NAOL           =   8 # Output Line Width
NAOP           =   9 # Output Page Size
NAOCRD         =  10 # Output Carriage-Return Disposition - RFC 652
NAOHTS         =  11 # Output Horizontal Tab Stops - RFC 653
NAOHTD         =  12 # Output Horizontal Tab Disposition - RFC 654
NAOFFD         =  13 # Output Formfeed Disposition - RFC 655
NAOVTS         =  14 # Output Vertical Tabstops - RFC 656
NAOVTD         =  15 # Output Vertical Tab Disposition - RFC 657
NAOLFD         =  16 # Output Linefeed Disposition - RFC 658
XASCII         =  17 # Extended ASCII - RFC 698
LOGOUT         =  18 # Logout - RFC 727
BM             =  19 # Byte Macro - RFC 735
DET            =  20 # Data Entry Terminal - RFC 732, 1043
SUPDUP         =  21 # SUPDUP - RFC 734, 736
SUPDUPOUTPUT   =  22 # SUPDUP Output - RFC 749
SNDLOC         =  23 # Send Location - RFC 779
TTYPE          =  24 # Terminal Type - RFC 1091
EOREC          =  25 # End of Record - RFC 885
TUID           =  26 # TACACS User Identification - RFC 927
OUTMRK         =  27 # Output Marking - RFC 933
TTYLOC         =  28 # Terminal Location Number - RFC 946
REGIME3270     =  29 # Telnet 3270 Regime - RFC 1041
X3PAD          =  30 # X.3 PAD - RFC 1053
NAWS           =  31 # Negotiate About Window Size - RFC 1073
TSPEED         =  32 # Terminal Speed - RFC 1079
LFLOW          =  33 # Remote Flow Control - RFC 1372
LINEMODE       =  34 # Linemode - RFC 1184
XDISPLOC       =  35 # X Display Location - RFC 1096
ENVIRON        =  36 # Environment Option - RFC 1408
AUTHENTICATION =  37 # Authentication Option - RFC 1416, 2941, 2942, 2943, 2951
ENCRYPT        =  38 # Encryption Option - RFC 2946
NEW_ENVIRON    =  39 # New Environment Option - RFC 1572
TN3270         =  40 # TN3270 Terminal Entry - RFC 2355
XAUTH          =  41 # XAUTH
CHARSET        =  42 # Charset option - RFC 2066
RSP            =  43 # Remote Serial Port
CPCO           =  44 # COM port Control Option - RFC 2217
SUPLECHO       =  45 # Suppress Local Echo
TLS            =  46 # Telnet Start TLS
KERMIT         =  47 # Kermit tranfer Option - RFC 2840
SENDURL        =  48 # Send URL
FORWARDX       =  49 # Forward X
PLOGON         = 138 # Telnet Pragma Logon
SSPI           = 139 # Telnet SSPI Logon
PHEARTBEAT     = 140 # Telnat Pragma Heartbeat
EXOPL          = 255 # Extended-Options-List - RFC 861
COMPRESS =  85 # MCCP 1 support (broken)
COMPRESS2 = 86 # MCCP 2 support
MSP  = 90 # MSP  support
MSP2 = 92 # MSP2 support
  MUSIC = 0
  SOUND = 1
ZMP = 93 # ZMP support

TELOPT_MXP      = 91


WILL_MCCP =   IAC.chr + WILL.chr + COMPRESS2.chr + "\0"
START_MCCP =  IAC.chr + SB.chr + COMPRESS2.chr + IAC.chr + SE.chr + "\0"
DO_MCCP =   IAC.chr + DO.chr + COMPRESS2.chr + "\0"
DONT_MCCP = IAC.chr + DONT.chr + COMPRESS2.chr + "\0"

WILL_MXP  =   IAC.chr + WILL.chr + TELOPT_MXP.chr + "\0"
START_MXP =   IAC.chr + SB.chr + TELOPT_MXP.chr + IAC.chr + SE.chr + "\0"
DO_MXP    =   IAC.chr+ DO.chr + TELOPT_MXP.chr + "\0" 
DONT_MXP  =   IAC.chr+ DONT.chr + TELOPT_MXP.chr + "\0"


DO_ECHO     = IAC.chr + WONT.chr + TELOPT_ECHO.chr + "\0"
DONT_ECHO     = IAC.chr + WILL.chr + TELOPT_ECHO.chr + "\0"

#########################
# End of Telnet support #
#########################

# the size of the event queue
MAX_EVENT_HASH =  128
ROOM_ON_CREATE =  1

$color_table = {
    "#z" => "\e[0;30m",
    "#Z" => "\e[1;30m",
    "#r" => "\e[0;31m",
    "#R" => "\e[1;31m",
    "#g" => "\e[0;32m",
    "#G" => "\e[1;32m",
    "#y" => "\e[0;33m",
    "#Y" => "\e[1;33m",
    "#b" => "\e[0;34m",
    "#B" => "\e[1;34m",
    "#p" => "\e[0;35m",
    "#P" => "\e[1;35m",
    "#c" => "\e[0;36m",
    "#C" => "\e[1;36m",
    "#w" => "\e[0;37m",
    "#W" => "\e[1;37m",
    "#n" => "\e[0m",
    "#u" => "",
    "#D" => "\e[1;30m",
    "##" => "#"
  }

$comp_tab = []
### compiles a table of values
$color_table.each_key do |k|
  $comp_tab << k
end
$comp_tab = Regexp.union(*$comp_tab)

ENDL = "\r\n"  ### alias for end of line.

$tabWizCmd = []
$tabCmd = []

class Command
  attr :cmd_name, :cmd_funct, :cmd_args, :must_type_full, :hidden
  attr_writer :cmd_args
  def initialize n, a, full=false, h=false
    @cmd_name = n
    @cmd_funct = ("cmd_"+n).to_sym
    @cmd_args = a
    @hidden = h
    @must_type_full = full
  end

  def hash
    [cmd_name].hash
  end

  def eql?(other)
    [cmd_name].eql?([other.cmd_name])
  end
  
end


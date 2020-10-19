#!/bin/bash
VER=1.00
AUTHOR=MalaGaM
APTLIST="git tcl8.6-dev libssl-dev tcllib"
BINARYLIST="git openssl gcc"
TCLPACKAGELIST=""
TMP_DIR=".tmp"
BASEDIR=$(dirname "$0")
ROOTDIR=`pwd`
EGGDROP_URL_GIT="https://github.com/eggheads/eggdrop.git"
DEFAULT_EGGDROP_CONFIGURE="--enable-tls --disable-ipv6"
DEFAULT_EGGDROP_DISABLE_MODULES="woobie uptime ctcp transfer share compress filesys notes seen assoc ident"
DEFAULT_EGGDROP_DEST="/home/eggdrop"
CACHE="$ROOTDIR/install.cache"
banner()
{
	if test -z "$2"
	then
		read -t 5 -p "[*] I am going to wait for 5 seconds or Press any key to continue . . ."
	fi
	clear
	echo "+--------------------------------------------------------------+"
	echo "| Eggdrop Tools V$VER By $AUTHOR                               |"
	echo "|--------------------------------------------------------------|"
	printf "|`tput bold` %-60s `tput sgr0`|\n" "$1"
	echo "+--------------------------------------------------------------+"
	
}
if [ ! `whoami` = "root" ]; then
	echo "The installer should be run as root or sudo";
	exit 0;
fi


CLEAR_TMP_DIR() {
	if [ -d "$TMP_DIR" ]
	then
		rm -rf $TMP_DIR
	fi
	mkdir -p $TMP_DIR
}
EGGDROP_DOWNLOAD_FROM_GIT() {
	banner "Download last version of eggdrop" silent
	git clone $EGGDROP_URL_GIT $TMP_DIR/eggdrop
}
ADD_TO_CACHE(){
	if [ -f "$CACHE" ]
	then
		sed -i "/$1/d" $CACHE
	fi
	echo $1=\"$2\" >> $CACHE
	
}
EGGDROP_RUN_CONFIGURE(){
	banner "./configure options"
	echo "./configure --silent --prefix=\"$EGGDROP_DEST\" $EGGDROP_CONFIGURE"
	./configure --silent --prefix="$EGGDROP_DEST" $EGGDROP_CONFIGURE >/dev/null || ./configure --silent --prefix="$EGGDROP_DEST" $EGGDROP_CONFIGURE
}

EGGDROP_DISABLE_MODULE(){
	echo "
#  disabled_modules -- File which lists all Eggdrop modules that are
#                      disabled by default.
#
# Note:
#   -  Lines which start with a '#' character are ignored.
#   -  Every module name needs to be on its own line

# Woobie only serves as an example for module programming. No need to
# compile it for normal bots ...
" > disabled_modules
	for module in $DEFAULT_EGGDROP_DISABLE_MODULES; do
		echo "Disable: $module"
		echo "$module" >> disabled_modules
		sleep 0.1
	done
}
EGGDROP_CONFIG_CONFIGURE_PATH(){
	until [ -n "$EGGDROP_DEST" ]; do
		if [[ -f "$CACHE" && "`cat $CACHE | grep -w EGGDROP_DEST | wc -l`" = 1 ]]
		then
			DEFAULT_EGGDROP_DEST=`cat $CACHE | grep -w EGGDROP_DEST | cut -d "=" -f2 | tr -d "\""`
		fi
		echo -n "Please enter the private directory to install eggdrop [$DEFAULT_EGGDROP_DEST]: "
		read EGGDROP_DEST
		case $EGGDROP_DEST in
			/)
				echo "You can't have / as your private dir!  Try again."
				echo ""
				unset EGGDROP_DEST
				continue
			;;
			/*|"")
			[ -z "$EGGDROP_DEST" ] && EGGDROP_DEST="$DEFAULT_EGGDROP_DEST"
				[ -d "$EGGDROP_DEST" ] && {
					echo -n "Path already exists. [D]elete it, [A]bort, [T]ry again, [I]gnore? "
					read reply
					case $reply in
						[dD]*) rm -rf "$EGGDROP_DEST" ;;
						[tT]*) unset EGGDROP_DEST; continue ;;
						[iI]*) ;;
						*) echo "Aborted."; exit 1 ;;
					esac
				}
				mkdir -p "$EGGDROP_DEST"
				continue
			;;
			*)
				echo "The private directory must start with a \"/\".  Try again."
				echo ""
				unset EGGDROP_DEST
				continue
			;;
		esac
	done 
	ADD_TO_CACHE EGGDROP_DEST "$EGGDROP_DEST"
}
EGGDROP_CONFIG_CONFIGURE_ARGS(){
if [[ -f "$CACHE" && "`cat $CACHE | grep -w DEFAULT_EGGDROP_CONFIGURE | wc -l`" = 1 ]]
	then
		DEFAULT_EGGDROP_CONFIGURE=`cat $CACHE | grep -w EGGDROP_CONFIGURE | cut -d "=" -f2 | tr -d "\""`
	fi
	echo -n "Please enter the argument for ./configure, default: [$DEFAULT_EGGDROP_CONFIGURE]: "
	read EGGDROP_CONFIGURE
	if [ "$EGGDROP_CONFIGURE" = "" ] 
	then
		EGGDROP_CONFIGURE="$DEFAULT_EGGDROP_CONFIGURE"
	fi
	ADD_TO_CACHE EGGDROP_CONFIGURE "$EGGDROP_CONFIGURE"
}
EGGDROP_CONFIG_MODULES(){
	if [[ -f "$CACHE" && "`cat $CACHE | grep -w DEFAULT_EGGDROP_DISABLE_MODULES | wc -l`" = 1 ]]
	then
		DEFAULT_EGGDROP_DISABLE_MODULES=`cat $CACHE | grep -w EGGDROP_DISABLE_MODULES | cut -d "=" -f2 | tr -d "\""`
	fi
	echo -n "Please enter the list of disable modules, default: [$DEFAULT_EGGDROP_DISABLE_MODULES]: "
	read EGGDROP_DISABLE_MODULES
	if [ "$EGGDROP_DISABLE_MODULES" = "" ] 
	then
		EGGDROP_DISABLE_MODULES="$DEFAULT_EGGDROP_DISABLE_MODULES"
	fi
	ADD_TO_CACHE EGGDROP_DISABLE_MODULES "$EGGDROP_DISABLE_MODULES"
}
EGGDROP_CONFIG_DATADIR_CONF(){
	DEFAULT_EGGDROP_DATADIR_CONF="$EGGDROP_DEST/conf"
	if [[ -f "$CACHE" && "`cat $CACHE | grep -w DEFAULT_EGGDROP_DATADIR_CONF | wc -l`" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_CONF=`cat $CACHE | grep -w EGGDROP_DATADIR_CONF | cut -d "=" -f2 | tr -d "\""`
	fi
	echo -n "Please enter the path for config file (eggdrop.conf), default: [$DEFAULT_EGGDROP_DATADIR_CONF]: "
	read EGGDROP_DATADIR_CONF
	if [ "$EGGDROP_DATADIR_CONF" = "" ] 
	then
		EGGDROP_DATADIR_CONF="$DEFAULT_EGGDROP_DATADIR_CONF"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_CONF "$EGGDROP_DATADIR_CONF"
	[ ! -d "$EGGDROP_DATADIR_CONF/default" ] && mkdir -p $EGGDROP_DATADIR_CONF/default
}
EGGDROP_CONFIG_DATADIR_USERFILE(){
	DEFAULT_EGGDROP_DATADIR_USERFILE="$EGGDROP_DEST/data"
	if [[ -f "$CACHE" && "`cat $CACHE | grep -w DEFAULT_EGGDROP_DATADIR_USERFILE | wc -l`" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_USERFILE=`cat $CACHE | grep -w EGGDROP_DATADIR_USERFILE | cut -d "=" -f2 | tr -d "\""`
	fi
	echo -n "Please enter the path for user/chan/notes/ssl files, default: [$DEFAULT_EGGDROP_DATADIR_USERFILE]: "
	read EGGDROP_DATADIR_USERFILE
	if [ "$EGGDROP_DATADIR_USERFILE" = "" ] 
	then
		EGGDROP_DATADIR_USERFILE="$DEFAULT_EGGDROP_DATADIR_USERFILE"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_USERFILE "$EGGDROP_DATADIR_USERFILE"
	[ ! -d "$EGGDROP_DATADIR_USERFILE" ] && mkdir -p $EGGDROP_DATADIR_USERFILE
}
EGGDROP_CONFIG_DATADIR_CRONTABFILE(){
	DEFAULT_EGGDROP_DATADIR_CRONTABFILE="$EGGDROP_DEST/cron"
	if [[ -f "$CACHE" && "`cat $CACHE | grep -w DEFAULT_EGGDROP_DATADIR_CRONTABFILE | wc -l`" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_CRONTABFILE=`cat $CACHE | grep -w EGGDROP_DATADIR_CRONTABFILE | cut -d "=" -f2 | tr -d "\""`
	fi
	echo -n "Please enter the path for crontab files, default: [$DEFAULT_EGGDROP_DATADIR_CRONTABFILE]: "
	read EGGDROP_DATADIR_CRONTABFILE
	if [ "$EGGDROP_DATADIR_CRONTABFILE" = "" ] 
	then
		EGGDROP_DATADIR_CRONTABFILE="$DEFAULT_EGGDROP_DATADIR_CRONTABFILE"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_CRONTABFILE "$EGGDROP_DATADIR_CRONTABFILE"
	[ ! -d "$EGGDROP_DATADIR_CRONTABFILE" ] && mkdir -p $EGGDROP_DATADIR_CRONTABFILE
}



EGGDROP_CONFIG_USER(){
	banner "Configuration"
	if [ -f "$CACHE" ];
	then
		echo -n "A cache file was found. Do you want to have the latest default configuration entries? [Y]es [N]o, default N :"; read wantcache
		case $wantcache in
			[Yy])
				continue
			;;
			[Nn])
				rm $CACHE
			;;
			*)
				rm $CACHE
			;;
		esac
	fi
	EGGDROP_CONFIG_CONFIGURE_PATH
	EGGDROP_CONFIG_MODULES
	EGGDROP_CONFIG_CONFIGURE_ARGS
	EGGDROP_CONFIG_DATADIR_USERFILE
	EGGDROP_CONFIG_DATADIR_CRONTABFILE
	EGGDROP_CONFIG_DATADIR_CONF

}
EGGDROP_CREATE_EXAMPLE_CONF(){
cat > $EGGDROP_DATADIR_CONF/example.conf.dist << EOF
#! $EGGDROP_DEST/eggdrop

# Auto generated by eggdrop-tools.sh
# by MalaGaM.ARTiSPRETiS@GMail.Com
# https://github.com/MalaGaM/eggdrop-tools


# Set the nick the bot uses on IRC, and on the botnet unless you specify a
# separate botnet-nick, here.
set nick            "<ChangeMyNick>"

# This setting is used only for info to share with others on your botnet.
# Set this to the IRC network your bot is connected to.
set network         "<ChangeMyNetWork>"


# ####### NE PAS ENLEVER, NI DEPLACER
# Chargement des configurations par defaults
set longbotname     "<ChangeMyNetWork>-<ChangeMyNick>"
#####################################

source conf/default/eggdrop.conf


# ####### NE PAS ENLEVER, NI DEPLACER

# This is the bot's server list. The bot will start at the first server listed,
# and cycle through them whenever it gets disconnected. You need to change these
# servers to YOUR network's servers.
#
# The format is:
#   addserver <server> [port [password]]
# Prefix the port with a plus sign to attempt a SSL connection:
#   addserver <server> +port [password]
#
addserver ChanngeMyServerAddresse
# addserver you.need.to.change.this 6667
# addserver another.example.com 6669 password
# addserver 2001:db8:618:5c0:263:: 6669 password
# addserver ssl.example.net +7000

##### BOTNET/DCC/TELNET #####

listen <ChangeMyUserPort> users
listen <ChangeMyBotPort> bots

# First cmd
bind evnt - init-server evnt:init_server
proc evnt:init_server {type} {
  putserv "MODE \${::nick} +ihb-ws";
  putserv "nickserv register ChangeMyServicePassword no@nomail.com";
  putserv "PRIVMSG nickserv :RECOVER \${::nick} ChangeMyServicePassword";
  putserv "NICK $::nick";
  putserv "PRIVMSG nickserv :identify ChangeMyServicePassword";
  foreach channel [channels] { 
    putserv "PRIVMSG ChanServ :invite \${channel}"
    putserv "JOIN \${channel}"
  }
}
EOF
}
EGGDROP_INSTALL_CONF(){
	printf "|`tput bold` %-60s `tput sgr0`|\n" "Move conf files to '$EGGDROP_DATADIR_CONF'"
	mv $EGGDROP_DEST/eggdrop.conf $EGGDROP_DATADIR_CONF/default
	mv $EGGDROP_DEST/eggdrop-basic.conf $EGGDROP_DATADIR_CONF/default
	# copy cache file to dest dir
	cp --force $CACHE $EGGDROP_DEST
	
	# Active all modules
	sed -i 's/#loadmodule/loadmodule/g' $EGGDROP_DATADIR_CONF/default/eggdrop.conf
	sed -i 's/#loadmodule/loadmodule/g' $EGGDROP_DATADIR_CONF/default/eggdrop-basic.conf
	# Now disable all module marked
	for module in $EGGDROP_DISABLE_MODULES; do
		sed -i "s/loadmodule $module/#loadmodule $module/g" $EGGDROP_DATADIR_CONF/default/eggdrop.conf
		sed -i "s/loadmodule $module/#loadmodule $module/g" $EGGDROP_DATADIR_CONF/default/eggdrop-basic.conf
	done
	
	
}
EGGDROP_MAKE(){
	echo "+--------------------------------------------------------------+"
	banner "Eggdrop build"
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j config"
	make -j config >/dev/null || make -j config
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j"
	make -j >/dev/null || make -j
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j install"
	make install -j >/dev/null || make -j install
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make sslsilent"
	make sslsilent >/dev/null || make sslsilent
	echo "+--------------------------------------------------------------+"
}
EGGDROP_INSTALL(){
	CHECK_DEP
	EGGDROP_CONFIG_USER
	CLEAR_TMP_DIR
	EGGDROP_DOWNLOAD_FROM_GIT
	cd $TMP_DIR/eggdrop
	EGGDROP_DISABLE_MODULE
	EGGDROP_RUN_CONFIGURE
	EGGDROP_MAKE
	EGGDROP_INSTALL_CONF
	EGGDROP_CREATE_EXAMPLE_CONF

	
	cd $EGGDROP_DEST
	banner "Eggdrop Installed in '$EGGDROP_DEST'. Test run :"
	./eggdrop -v
	sleep 10
	
	cd $ROOTDIR

}
CHECK_DEP(){
		banner "Install dependancies" silent
		for pkg in $APTLIST; do
		if apt-get -qq -y --install-suggests -o Dpkg::Use-Pty=0 install $pkg ; then
			echo "Successfully installed $pkg"
		else
			echo "Error installing $pkg"
			exit
		fi
	done
	banner "Check binary dependancies"
	for cmd in $BINARYLIST; do
		if ! command -v $cmd &> /dev/null
		then
			echo "$cmd need be installed."
			exit
		else
			echo "Binary $cmd is installed."
		fi
	done
}

EGGDROP_SHOW_HELP()
{
	banner "Help" silent
	printf "|`tput bold` %-60s `tput sgr0`|\n" "-i|-install     | Install eggdrop"
	echo "+--------------------------------------------------------------+"
	exit
}
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--install)
    EGGDROP_INSTALL;
    shift # past argument
    shift # past value
    ;;
    -h|--h|-help|--help)
    EGGDROP_SHOW_HELP
    shift # past argument
    shift # past value
    ;;
    -l|--lib)
    LIBPATH="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
	exit
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

banner "Menu" silent
PS3='-> Please enter your choice: '
options=("Install" "AddBot" "AddCrontab" "Quit")
select opt in "${options[@]}"
do
	case $opt in
		"Install")
			EGGDROP_INSTALL;
			break;
			;;
		"AddBot")
			echo "you chose choice 2"
			;;
		"AddCrontab")
			echo "you chose choice $REPLY which is $opt"
			;;
		"Quit")
			break
			;;
		*) echo "invalid option $REPLY";;
	esac
done
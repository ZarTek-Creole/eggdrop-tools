#!/bin/bash
VER=1.00
AUTHOR=ZarTek
APTLIST="git tcl8.6-dev libssl-dev tcllib curl"
BINARYLIST="git openssl gcc curl"
TMP_DIR=".tmp"
ROOTDIR=$(pwd)
EGGDROP_URL_GIT="https://github.com/eggheads/eggdrop.git"
EGGDROP_URL_STABLE="https://ftp.eggheads.org/pub/eggdrop/source/eggdrop1.8-latest.tar.gz"
DEFAULT_EGGDROP_VERSION="dev"
DEFAULT_EGGDROP_CONFIGURE="--enable-tls --disable-ipv6"
DEFAULT_EGGDROP_DISABLE_MODULES="woobie uptime ctcp transfer share compress filesys notes seen assoc ident"
DEFAULT_EGGDROP_DEST="/home/eggdrop"
CACHE="$ROOTDIR/install.cache"
banner()
{
	if test -z "$2"
	then
		read -r -t 5 -p "[*] I am going to wait for 5 seconds or Press any key to continue . . ."
	fi
	clear
	echo "+--------------------------------------------------------------+"
	echo "| Eggdrop Tools V$VER By $AUTHOR                               |"
	echo "+--------------------------------------------------------------+"
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "$1"
	echo "+--------------------------------------------------------------+"
	
}
if [ ! "$(whoami)" = "root" ]; then
	echo "The installer should be run as root or sudo";
	exit 0;
fi


CLEAR_TMP_DIR() {
	if [ -d "$TMP_DIR" ]
	then
		rm -rf "$TMP_DIR"
	fi
	mkdir -p "$TMP_DIR"
}
EGGDROP_DOWNLOAD_GIT_VERSION() {
	banner "Download last 'Dev/Git' version of eggdrop" silent
	git clone "$EGGDROP_URL_GIT" "$TMP_DIR/eggdrop"
	cd "$TMP_DIR/eggdrop" || exit
}
EGGDROP_DOWNLOAD_STABLE_VERSION() {
	banner "Download last version 'Stable/Tarball' of eggdrop" silent
	curl "$EGGDROP_URL_STABLE" | tar -xz -C "$TMP_DIR"
	cd "$TMP_DIR/eggdrop-1.8.4" || exit
}
ADD_TO_CACHE(){
	if [ -f "$CACHE" ]
	then
		sed -i "/$1/d" "$CACHE"
	fi
	echo "$1"=\""$2"\" >> "$CACHE"
	
}
EGGDROP_RUN_CONFIGURE(){
	banner "./configure options"
	echo "|-> ./configure --silent --prefix=$EGGDROP_DEST $EGGDROP_CONFIGURE"
	./configure --silent --prefix=$EGGDROP_DEST $EGGDROP_CONFIGURE >/dev/null || ./configure --silent --prefix=$EGGDROP_DEST $EGGDROP_CONFIGURE
}

EGGDROP_DISABLE_MODULE(){
banner "Disable modulesof eggdrop" silent
	echo "
# disabled_modules -- File which lists all Eggdrop modules that are
# disabled by default.
#
# Note:
#	- Lines which start with a '#' character are ignored.
#	- Every module name needs to be on its own line

# Woobie only serves as an example for module programming. No need to
# compile it for normal bots ...
" > disabled_modules
	for module in $DEFAULT_EGGDROP_DISABLE_MODULES; do
		echo "Disable: $module"
		echo "$module" >> disabled_modules
		sleep 0.1
	done
}
USER_SET_EGG_VERS(){
	
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_VERSION "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_VERSION=$(grep -w EGGDROP_VERSION "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Install stable or dev version of eggdrop ? [stable] [dev], default $DEFAULT_EGGDROP_VERSION : ";
	read -r EGGDROP_VERSION
	if [ "$EGGDROP_VERSION" = "" ] 
	then
		EGGDROP_VERSION="$DEFAULT_EGGDROP_VERSION"
	fi
	ADD_TO_CACHE EGGDROP_VERSION "$EGGDROP_VERSION"
}
USER_SET_DEST(){
	until [ -n "$EGGDROP_DEST" ]; do
		if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DEST "$CACHE")" = 1 ]]
		then
			DEFAULT_EGGDROP_DEST=$(grep -w EGGDROP_DEST "$CACHE" | cut -d "=" -f2 | tr -d "\"")
		fi
		echo -n "Please enter the private directory to install eggdrop [$DEFAULT_EGGDROP_DEST]: "
		read -r EGGDROP_DEST
		case $EGGDROP_DEST in
			/)
				echo "You can't have / as your private dir!	 Try again."
				echo ""
				unset EGGDROP_DEST
				continue
			;;
			/*|"")
			[ -z "$EGGDROP_DEST" ] && EGGDROP_DEST="$DEFAULT_EGGDROP_DEST"
				[ -d "$EGGDROP_DEST" ] && {
					echo -n "Path already exists. [D]elete it, [A]bort, [T]ry again, [I]gnore? "
					read -r reply
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
				echo "The private directory must start with a \"/\". Try again."
				echo ""
				unset EGGDROP_DEST
				continue
			;;
		esac
	done 
	ADD_TO_CACHE EGGDROP_DEST "$EGGDROP_DEST"
}
USER_SET_CONFIGURE_ARGS(){
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_CONFIGURE "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_CONFIGURE=$(grep -w EGGDROP_CONFIGURE "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the argument for ./configure, default: [$DEFAULT_EGGDROP_CONFIGURE]: "
	read -r EGGDROP_CONFIGURE
	if [ "$EGGDROP_CONFIGURE" = "" ] 
	then
		EGGDROP_CONFIGURE="$DEFAULT_EGGDROP_CONFIGURE"
	fi
	ADD_TO_CACHE EGGDROP_CONFIGURE "$EGGDROP_CONFIGURE"
}
USER_SET_MODULES(){
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DISABLE_MODULES "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_DISABLE_MODULES=$(grep -w EGGDROP_DISABLE_MODULES "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the list of disable modules, default: [$DEFAULT_EGGDROP_DISABLE_MODULES]: "
	read -r EGGDROP_DISABLE_MODULES
	if [ "$EGGDROP_DISABLE_MODULES" = "" ] 
	then
		EGGDROP_DISABLE_MODULES="$DEFAULT_EGGDROP_DISABLE_MODULES"
	fi
	ADD_TO_CACHE EGGDROP_DISABLE_MODULES "$EGGDROP_DISABLE_MODULES"
}
USER_SET_DATADIR_CONF(){
	DEFAULT_EGGDROP_DATADIR_CONF="$EGGDROP_DEST/conf"
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DATADIR_CONF "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_CONF=$(grep -w EGGDROP_DATADIR_CONF "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the path for config file (eggdrop.conf), default: [$DEFAULT_EGGDROP_DATADIR_CONF]: "
	read -r EGGDROP_DATADIR_CONF
	if [ "$EGGDROP_DATADIR_CONF" = "" ] 
	then
		EGGDROP_DATADIR_CONF="$DEFAULT_EGGDROP_DATADIR_CONF"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_CONF "$EGGDROP_DATADIR_CONF"
	[ ! -d "$EGGDROP_DATADIR_CONF/default" ] && mkdir -p "$EGGDROP_DATADIR_CONF/default"
}
USER_SET_DATAROOTDIR(){
	DEFAULT_EGGDROP_DATADIR_USERFILE="$EGGDROP_DEST/data"
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DATADIR_USERFILE "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_USERFILE=$(grep -w EGGDROP_DATADIR_USERFILE "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the path for ROOTDIR for data files, default: [$DEFAULT_EGGDROP_DATADIR_USERFILE]: "
	read -r EGGDROP_DATADIR_USERFILE
	if [ "$EGGDROP_DATADIR_USERFILE" = "" ] 
	then
		EGGDROP_DATADIR_USERFILE="$DEFAULT_EGGDROP_DATADIR_USERFILE"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_USERFILE "$EGGDROP_DATADIR_USERFILE"
	[ ! -d "$EGGDROP_DATADIR_USERFILE" ] && mkdir -p "$EGGDROP_DATADIR_USERFILE"
}
USER_SET_DATADIR_CRON(){
	DEFAULT_EGGDROP_DATADIR_CRONTABFILE="$EGGDROP_DATADIR_USERFILE/cron"
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DATADIR_CRONTABFILE "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_CRONTABFILE=$(grep -w EGGDROP_DATADIR_CRONTABFILE "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the path for crontab files, default: [$DEFAULT_EGGDROP_DATADIR_CRONTABFILE]: "
	read -r EGGDROP_DATADIR_CRONTABFILE
	if [ "$EGGDROP_DATADIR_CRONTABFILE" = "" ] 
	then
		EGGDROP_DATADIR_CRONTABFILE="$DEFAULT_EGGDROP_DATADIR_CRONTABFILE"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_CRONTABFILE "$EGGDROP_DATADIR_CRONTABFILE"
	[ ! -d "$EGGDROP_DATADIR_CRONTABFILE" ] && mkdir -p "$EGGDROP_DATADIR_CRONTABFILE"
}
USER_SET_DATADIR_SSL(){
	DEFAULT_EGGDROP_DATADIR_SSL="$EGGDROP_DATADIR_USERFILE/ssl"
	if [[ -f "$CACHE" && "$(grep -c -w EGGDROP_DATADIR_SSL "$CACHE")" = 1 ]]
	then
		DEFAULT_EGGDROP_DATADIR_SSL=$(grep -w EGGDROP_DATADIR_SSL "$CACHE" | cut -d "=" -f2 | tr -d "\"")
	fi
	echo -n "Please enter the path for SSL files, default: [$DEFAULT_EGGDROP_DATADIR_SSL]: "
	read -r EGGDROP_DATADIR_SSL
	if [ "$EGGDROP_DATADIR_SSL" = "" ] 
	then
		EGGDROP_DATADIR_SSL="$DEFAULT_EGGDROP_DATADIR_SSL"
	fi
	ADD_TO_CACHE EGGDROP_DATADIR_SSL "$EGGDROP_DATADIR_SSL"
	[ ! -d "$EGGDROP_DATADIR_SSL" ] && mkdir -p "$EGGDROP_DATADIR_SSL"
}



USER_CHOICE_CONFIGURATION(){
	banner "Prompt User Configuration"
	if [ -f "$CACHE" ];
	then
		echo -n "A cache file was found. Do you want to have the latest default configuration entries? [Y]es [N]o, default Y :"; read -r wantcache
		case $wantcache in
			[Yy])
				;;
			[Nn])
				rm "$CACHE"
				;;
			*)
				;;
		esac
	fi
	USER_SET_EGG_VERS
	USER_SET_DEST
	USER_SET_MODULES
	USER_SET_CONFIGURE_ARGS
	USER_SET_DATAROOTDIR
	USER_SET_DATADIR_SSL
	USER_SET_DATADIR_CRON
	USER_SET_DATADIR_CONF

}
GENERATE_CERTIFICATS(){
	banner "Generate certificats files"
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "Generate KEY AND CRT file"
	openssl req -new -x509 -nodes \
		-days 365 \
		-keyout "$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop.key" \
		-out "$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop.crt" -config ssl.conf \
		-subj "/O=Eggheads/OU=Eggdrop/CN=Self-generated Eggdrop Certificate"&>/dev/null
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "Generate DH PEM file" 
	openssl dhparam \
		-dsaparam \
		-out "$DEFAULT_EGGDROP_DATADIR_SSL/dhparam.pem" 4096 &>/dev/null
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "Generate ECDSA PEM file"
	openssl ecparam -genkey \
		-name prime256v1 \
		-out "$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop-ecdsa.pem" &>/dev/null
	echo "+--------------------------------------------------------------+"

}
EGGDROP_CREATE_EXAMPLE_CONF(){
cat > "$EGGDROP_DATADIR_CONF/example.conf.dist" << EOF
#! $EGGDROP_DEST/eggdrop

# Auto generated by eggdrop-tools.sh
# by ZarTek.Creole@GMail.Com
# github.com/ZarTek-Creole/eggdrop-tools
#
# Change value into <> begin with <Change...>

# Set the nick the bot uses on IRC, and on the botnet unless you specify a
# separate botnet-nick, here.
set nick			"<ChangeMyNick>"

# This setting defines the username the bot uses on IRC. This setting has no
# effect if an ident daemon is running on your bot's machine. See also ident
# module.
set username "\$nick"

# Set what should be displayed in the real-name field for the bot on IRC.
# This can not be blank, it has to contain something.
set realname "I'am an bot, my name is \$nick"

# This setting is used only for info to share with others on your botnet.
# Set this to the IRC network your bot is connected to.
set network			"<ChangeMyNetWork>"


# ####### NE PAS ENLEVER, NI DEPLACER
# Chargement des configurations par defaults
# Ceci est une variable creer par eggdrop-tools, elle permet de reconnaitre
# les differents bots en diferenciant par le nom du reseau et le nom du bot utiliser sur IRC.
# Ne suprimer pas cette variables, si vous la changer, les nom des fichier user/chan/notes changerons égallement
##
set longbotname		"\$network-\$nick"
#####################################

# Vous avez le choix entre une configuration global complete dans
# $EGGDROP_DATADIR_CONF/default/eggdrop.conf
# ou une configuration simplifier/basique dans 
# $EGGDROP_DATADIR_CONF/default/eggdrop-basic.conf
# Choisisez ce qui vous correpond le mieux.
# Peut importe celle que vous choisisez, si vous editer le fichier de configuration
# les changements seront appliquer a tout les eggdrops.
# si vous desirez modifier qu'une seule valeur pour un seul bot modifier dans le fichier
# $EGGDROP_DATADIR_CONF/<network>-<nick>.conf
###
# Par default configuration complete :
source $EGGDROP_DATADIR_CONF/default/eggdrop.conf
# Commenter ci dessus avec un #, et enlever le # ci dessous pour utiliser la configration simplifier:
#source $EGGDROP_DATADIR_CONF/default/eggdrop-basic.conf

# ####### NE PAS ENLEVER, NI DEPLACER

# This is the bot's server list. The bot will start at the first server listed,
# and cycle through them whenever it gets disconnected. You need to change these
# servers to YOUR network's servers.
#
# The format is:
#	addserver <server> [port [password]]
# Prefix the port with a plus sign to attempt a SSL connection:
#	addserver <server> +port [password]
#
addserver ChanngeMyServerAddresse
# addserver you.need.to.change.this 6667
# addserver another.example.com 6669 password
# addserver 2001:db8:618:5c0:263:: 6669 password
# addserver ssl.example.net +7000

## What is your network?
##	 If your network is not specifically listed here, please see eggdrop.conf
##	 for more information on what the best selection is.
## Options are:
##	 EFnet
##	 IRCnet
##	 Undernet
##	 DALnet
##	 freenode
##	 QuakeNet
##	 Rizon
##	 Other	(This is a good, sane default option to use if your network/ircd is
##			not listed here. Additional configuration options for this setting
##			can be found further down in the IRC MODULE section)
set net-type "EFnet"

##### BOTNET/DCC/TELNET #####

listen <ChangeMyUserPort> users
listen <ChangeMyBotPort> bots

# First cmd
bind evnt - init-server evnt:init_server
proc evnt:init_server {type} {
	putserv "MODE \${::nick} +ihb-ws";
	putserv "nickserv register <ChangeMyServicePassword> <ChangeMyServiceMail>";
	putserv "PRIVMSG nickserv :RECOVER \${::nick} <ChangeMyServicePassword>";
	putserv "NICK $::nick";
	putserv "PRIVMSG nickserv :identify <ChangeMyServicePassword>";
	foreach channel [channels] { 
		putserv "PRIVMSG ChanServ :invite \${channel}"
		putserv "JOIN \${channel}"
	}
}
EOF
}
EGGDROP_INSTALL_CONF(){
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "Move conf files to '$EGGDROP_DATADIR_CONF'"
	mv "$EGGDROP_DEST/eggdrop.conf" "$EGGDROP_DATADIR_CONF/default"
	mv "$EGGDROP_DEST/eggdrop-basic.conf" "$EGGDROP_DATADIR_CONF/default"
	# copy cache file to dest dir
	cp --force "$CACHE" "$EGGDROP_DEST"
	
	local fconf="$EGGDROP_DATADIR_CONF/default/eggdrop.conf"
	local fconfb="$EGGDROP_DATADIR_CONF/default/eggdrop-basic.conf"
	
	# Active all modules
	SED_REPLACE "#loadmodule"	\
				"loadmodule"	\
				"$fconf $fconfb"
	# Now disable all module marked
	for module in $EGGDROP_DISABLE_MODULES; do
		SED_REPLACE "loadmodule $module" "#loadmodule $module" "$fconf $fconfb"
	done
	#change path for SSL file
		# key file
	SED_REPLACE "#set ssl-privatekey \"eggdrop.key\""		\
				"set ssl-privatekey \"$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop.key\""		\
				"$fconf $fconfb"
		# certificats file
	SED_REPLACE "#set ssl-certificate \"eggdrop.crt\""		\
				"set ssl-certificate \"$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop.crt\""		\
				"$fconf $fconfb"
		# dhparam file
	SED_REPLACE "#set ssl-dhparam \"dhparam.pem\""			\
				"set ssl-dhparam \"$DEFAULT_EGGDROP_DATADIR_SSL/dhparam.pem\""			\
				"$fconf $fconfb"
		# ECDSA certificate file
	SED_REPLACE "#set sasl-ecdsa-key \"eggdrop-ecdsa.pem\""	\
				"set sasl-ecdsa-key \"$DEFAULT_EGGDROP_DATADIR_SSL/eggdrop-ecdsa.pem\""	\
				"$fconf $fconfb"
	
	# comment setting used in example.conf.dist
		# set nick
	SED_COMMENT 'set nick "Lamestbot"' \
				"$fconf $fconfb"
		# set username
	SED_COMMENT 'set username "lamest"' \
				"$fconf $fconfb"
		# set network
	SED_COMMENT "set network \"I.didn't.edit.my.config.file.net\"" \
				"$fconf $fconfb"
		# set addserver
	SED_REPLACE 'addserver '	\
				'#addserver '	\
				"$fconf $fconfb"
		# set net-type
	SED_COMMENT 'set net-type "EFnet"' \
				"$fconf $fconfb"
	# set logfile
	SED_COMMENT 'logfile mco * "logs/eggdrop.log"' \
				"$fconf $fconfb"
		# set realname
	SED_COMMENT 'set realname "/msg LamestBot hello"' \
				"$fconf $fconfb"
		# set userfile
	SED_REPLACE "set userfile \"LamestBot.user\""	\
				"set userfile \"$EGGDROP_DATADIR_USERFILE/\$longbotname.user\""	\
				"$fconf $fconfb"
		# set chanfile
	SED_REPLACE "set chanfile \"LamestBot.chan\""	\
				"set chanfile \"$EGGDROP_DATADIR_USERFILE/\$longbotname.chan\""	\
				"$fconf $fconfb"
		# set notefile
	SED_REPLACE "set notefile \"LamestBot.notes\""	\
				"set notefile \"$EGGDROP_DATADIR_USERFILE/\$longbotname.notes\""	\
				"$fconf $fconfb"
		# set pidfile
	SED_REPLACE "#set pidfile \"pid.LamestBot\""	\
				"set pidfile \"$EGGDROP_DATADIR_USERFILE/pid.\$longbotname\""	\
				"$fconf $fconfb"
}
EGGDROP_MAKE(){
	echo "+--------------------------------------------------------------+"
	banner "Eggdrop build"
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "make -j config"
	make -j config >/dev/null || make -j config
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "make -j"
	make -j -w >/dev/null || make -j
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "make -j install"
	make install -j >/dev/null || make -j install
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "make sslsilent"
	echo "+--------------------------------------------------------------+"
}
EGGDROP_INSTALL(){
	CHECK_DEP
	USER_CHOICE_CONFIGURATION
	CLEAR_TMP_DIR
	if [ "${EGGDROP_VERSION,,}" = "dev" ]; then
		EGGDROP_DOWNLOAD_GIT_VERSION
	else
		EGGDROP_DOWNLOAD_STABLE_VERSION
	fi
	EGGDROP_DISABLE_MODULE
	EGGDROP_RUN_CONFIGURE
	EGGDROP_MAKE
	EGGDROP_INSTALL_CONF
	EGGDROP_CREATE_EXAMPLE_CONF
	GENERATE_CERTIFICATS

	
	cd "$EGGDROP_DEST" || exit
	banner "Eggdrop Installed in '$EGGDROP_DEST'. Test run :"
	./eggdrop -v
	sleep 10
	
	cd "$ROOTDIR" || exit

}
CHECK_DEP(){
		banner "check packages dependencies needed" silent
		for pkg in $APTLIST; do
		if apt-get -qq -y --install-suggests -o Dpkg::Use-Pty=0 install "$pkg" ; then
			echo "Successfully installed $pkg"
		else
			echo "Error installing $pkg"
			exit
		fi
	done
	banner "Check binary dependancies"
	for cmd in $BINARYLIST; do
		if ! command -v "$cmd" &> /dev/null
		then
			echo "$cmd need be installed."
			exit
		else
			echo "Binary $cmd is installed."
		fi
	done
}
SED_REPLACE() {
	local search=$1
	local replace=$2
	local infile=$3
	for file in $infile; do
		sed -i "s@${search}@${replace}@g" "${file}"
	done
}
SED_COMMENT() {
	local comment=$1
	local infile=$2
	for file in $infile; do
		sed -i "s@${comment}@#${comment}; #comment because used in example.conf.dist@g" "${file}"
	done
}

EGGDROP_SHOW_HELP()
{
	banner "Help" silent
	printf "|$(tput bold) %-60s $(tput sgr0)|\n" "-i|-install  | Install eggdrop"
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
	--default)
	#DEFAULT=YES
	shift # past argument
	;;
	*)	# unknown option
	exit
	POSITIONAL+=("$1") # save it in an array for later
	shift # past argument
	;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

MENU_SHOW()
{
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
			*) echo "invalid option $REPLY";MENU_SHOW;;
		esac
	done
}
MENU_SHOW
#!/bin/bash
VER=1.00
AUTHOR=MalaGaM
APTLIST="git tcl8.6-dev libssl-dev"
BINARYLIST="git"
TCLPACKAGELIST=""
TMP_DIR=".tmp"
BASEDIR=$(dirname "$0")
ROOTDIR=`pwd`
EGGDROP_URL_GIT="https://github.com/eggheads/eggdrop.git"
DEFAULT_EGGDROP_CONFIGURE="--enable-tls --disable-ipv6"
DEFAULT_EGGDROP_DISABLE_MODULES="woobie uptime"
DEFAULT_EGGDROP_DEST="/home/eggdrop"
CACHE="$ROOTDIR/install.cache"

if [ ! `whoami` = "root" ]; then
	echo "The installer should be run as root or sudo";
	exit 0;
fi
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
CLEAR_TMP_DIR() {
	if [ -d "$TMP_DIR" ]
	then
		rm -rf $TMP_DIR
	fi
	mkdir -p $TMP_DIR
}
EGGDROP_DOWNLOAD_FROM_GIT() {
	banner "Download last version of eggdrop"
	git clone $EGGDROP_URL_GIT $TMP_DIR/eggdrop
}
ADD_TO_CACHE(){
	sed -i "/$1/d" $CACHE
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
		sleep 1
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
EGGDROP_CONFIG_USER(){
	banner "Configuration"
	EGGDROP_CONFIG_CONFIGURE_PATH
	EGGDROP_CONFIG_MODULES
	EGGDROP_CONFIG_CONFIGURE_ARGS

}
EGGDROP_INSTALL(){
	CHECK_DEP
	EGGDROP_CONFIG_USER
	CLEAR_TMP_DIR
	EGGDROP_DOWNLOAD_FROM_GIT
	cd $TMP_DIR/eggdrop
	EGGDROP_DISABLE_MODULE
	EGGDROP_RUN_CONFIGURE
	echo "|--------------------------------------------------------------|"
	banner "Eggdrop build"
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j config"
	make -j config >/dev/null || make -j config
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j"
	make -j >/dev/null || make -j
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make -j install"
	make install -j >/dev/null || make -j install
	printf "|`tput bold` %-60s `tput sgr0`|\n" "make sslsilent"
	make sslsilent >/dev/null || make sslsilent
	cd $EGGDROP_DEST
	banner "Eggdrop Installed in '$EGGDROP_DEST'. Test run :"
	./eggdrop -v
	sleep 10
	
	cd $ROOTDIR

}
CHECK_DEP(){
		banner "Install dependancies" silent
		for pkg in $APTLIST; do
		if apt-get -qq -y -o Dpkg::Use-Pty=0 install $pkg ; then
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
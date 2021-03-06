#!/usr/bin/env bash
#
#==================================================================#
#   install-dockup.sh                                              #
#   
#   Installer script for dockup.sh - based directly on @gugod's
#   perlbrew installer script - https://install.perlbrew.pl
#   (github.com/gugod/App-perlbrew/blob/develop/perlbrew-install)
#                                                                  #
#==================================================================#


if [ -z "$DOCKUP_INSTALL_DIR" ]; then
  DOCKUP_INSTALL_DIR="/usr/local/bin"
fi

if [ -z "$TMPDIR" ]; then
    if [ -d "/tmp" ]; then
        TMPDIR="/tmp"
        cd $TMPDIR || clean_exit 1
    else
        TMPDIR="."
    fi
fi

clean_exit () {
    [ -f $LOCALINSTALLER ] && rm $LOCALINSTALLER
    exit $1
}

LOCALINSTALLER=$(mktemp $TMPDIR/_inst-dockup.XXXXXX)

if [ -z "${DOCKUPURL}" ]; then
    DOCKUPURL=https://raw.githubusercontent.com/docker-rapi/dockup.sh/master/dockup.sh
fi


echo
if type curl >/dev/null 2>&1; then
  DOCKUPDOWNLOAD="curl -f -sS -Lo $LOCALINSTALLER $DOCKUPURL"
elif type fetch >/dev/null 2>&1; then
  DOCKUPDOWNLOAD="fetch -o $LOCALINSTALLER $DOCKUPURL"
elif type wget >/dev/null 2>&1; then
  DOCKUPDOWNLOAD="wget -nv -O $LOCALINSTALLER $DOCKUPURL"
else
  echo "Need either wget, fetch or curl to use $0"
  clean_exit
fi


echo "## Downloading latest dockup.sh script..."
$DOCKUPDOWNLOAD || clean_exit 1

DLVERSION=$(bash $LOCALINSTALLER --version) || clean_exit 1
echo "   (Successfully downloaded v$DLVERSION)"

echo
echo "## Installing dockup.sh to '$DOCKUP_INSTALL_DIR' [using sudo]:"
echo "   (set DOCKUP_INSTALL_DIR to change)"
echo

sudo bash $LOCALINSTALLER --install $DOCKUP_INSTALL_DIR || clean_exit 1

echo
echo "## Done."

rm $LOCALINSTALLER

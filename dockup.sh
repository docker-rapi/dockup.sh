#!/usr/bin/env bash
#
#==============================================#
#   dockup.sh                                  #
#   github.com/docker-rapi/dockup.sh           #
    version=1.002                              #
#                                              #
#==============================================#
#


function usage () {
   cat <<EOF
 Usage:
   dockup.sh [APPDIR]? [-p PORT] [-n] [-c CONTAINER_NAME] [-i IMAGE_NAME]

 About dockup.sh:
   dockup.sh is a utility script which is designed to run perl Plack/PSGI 
   applications on-the-fly in a similar manner to 'plackup' but with docker and 
   the rapi/psgi DockerHub image, which is the preferred way to run 
   RapidApp-based applications (although it works for any PSGI application). 
   Like plackup, the target app dir should contain a valid app.psgi file which 
   will be used to start up a dedicated webserver on the local system on the 
   supplied port (which defaults to 5000, like plackup).

   This script simply generates and optionally runs a docker run/create command,
   it assumes/requires you already have a working installation of docker.

   See:   http://hub.docker.com/r/rapi/psgi/
          http://www.rapi.io


 Usage: 
   dockup.sh [APPDIR]? [-p PORT] [-n] [-c CONTAINER_NAME] [-i IMAGE_NAME]

   Options:
     [APPDIR]   First argument will be used as the app dir; defaults to the pwd
     --help     Display this help screen and exit
     --version  Print the dockup.sh version and exit
     --install  Script copies itself to the supplied path, defaults to /usr/local/bin/

     -p   TCP/IP port to start webserver on (defaults to 5000)
     -c   create container. Will generate a docker 'create' instead of 'run' command
     -i   Docker image to use, defaults to rapi/psgi
     -d   Download (docker pull) the latest image (-i) before running, default false

     -n   Dry-run; prints the docker command which would have been ran without 
          actually running it. This is useful both to be able to see the effect of 
          the options combination as well as be able to copy and paste it manually


 Examples:
   dockup.sh  # starts the app in the current directory with default options
   
   dockup.sh -p 5002
   dockup.sh -d -i rapi/psgi:1.3100
   dockup.sh /path/to/app -c myapp
   dockup.sh -n -p 5005 -c cool-thing -i my-docker-image

   ./dockup.sh --install  # Installs itself to the local system (/usr/local/bin)

EOF
   exit $1
}

if [ "$1" == "--version" ]; then echo $version; exit 0; fi

echo -e "-- dockup.sh $version --\n"

if [ "$1" == "--help" ]; then usage; fi

###########################################################


function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

if [ "$1" == "--install" ]; then
  installdir="/usr/local/bin"
  if [ "$2" ]; then installdir=$2; fi
  
  if [[ ! -d "$installdir" ]]; then
    echo "Install dir '$installdir' doesn't exist or is not a directory"
    exit 1
  fi
  
  targfile="$installdir/dockup.sh"
  if [ -f "$targfile" ]; then
    curversion=`bash $targfile --version`;
    if [ $? -ne 0 ]; then
      echo -e "\nError: $targfile already exists but is corrupt. Remove this file and try again.";
      exit 1;
    else
      if [ $curversion == $version ]; then
        echo -e "$targfile already installed (v$curversion)"
        exit 0;
      fi
      if version_gt $curversion $version; then
        echo -e "$targfile is already a newer version (v$curversion) -- won't install older version"
        exit 2;
      fi
      
      echo -e "Upgrading from v$curversion...\n"
    fi
  fi
  
  instcmds=(
    "cp -f ${BASH_SOURCE[0]} $targfile"
    "chmod ugo+rx $targfile"
  );
  
  for ((i = 0; i < ${#instcmds[@]}; i++)); do 
    echo "  -> ${instcmds[$i]}"
    `${instcmds[$i]}`
    if [ $? -ne 0 ]; then echo "   --> error, command failed, aborting"; exit 3; fi
  done
  
  newversion=`$targfile --version`;
  if [ $? -ne 0 ]; then echo " Unknown error occured; $targfile not installed correctly"; exit 4; fi
  
  if [ $newversion == $version ]; then
    echo -e "\nSuccessfully installed $targfile v$newversion"
    exit 0
  else
    echo -e "Unexpected error. Installed file (v$newversion) does not match source version (v$version)"
    exit 5
  fi
  
  exit 0;
fi


###########################################################

# Defaults:
port=5000
dockerimg="rapi/psgi"
dockercmd="docker run"
firstargs="--rm"


if [ $# -eq 0 ]; then noargs=1; fi

# The directory where this script resides:
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Start with the user's current working directory:
appdir=$PWD

# If the current dir doesn't have an app.psgi fallback to the script's parent dir:
if [ ! -f "$appdir/app.psgi" ]; then appdir=$scriptdir; fi

# Or, the user can explicitly provide the app dir as the first argument
if [[ $# -gt 0 && $1 != -* ]]; then
  if [[ ! -d "$1" ]]; then
    echo "Supplied application directory $1 not found"
    usage
  fi
  appdir="$( cd $1 && pwd )"
  shift # pull it out of the arg stack for getopts below
fi


ndx=0
for arg do
  ndx=$((ndx+1))
  if [ "$arg" == "--" ]; then
    # Capture everything after the -- into $extra (string)
    extra="${@:($ndx+1)}"
    
    # This is how we change the special argument array $@. Here we are truncating
    # after and including the '--' argument which we've already captured above
    set -- "${@:1:$ndx}"
    
    break # Only do this for the first '--'
  fi
done



while getopts "p:ndc:i:" opt; do
  case $opt in
    p) port=$OPTARG;;
    n) dryrun=1;;
    c) dockercmd="docker create"; firstargs="--name $OPTARG --hostname $OPTARG";;
    i) dockerimg=$OPTARG;;
    d) autopull=1;;
    \?|*) echo -e "\n"; usage 1;;
  esac
done
shift $((OPTIND -1))

# Catch any rogue words in the arg list that getopts didn't handle
if [ "$#" -gt "0" ]; then
  echo "Invalid extra arguments."
  usage
fi


if [ ! -f "$appdir/app.psgi" ]; then
  if [[ $noargs ]]; then usage; fi
  echo "Error: Could not determine app dir or no app.psgi file found."
  exit 1
fi

#echo "Using PSGI application dir: $appdir"


arg_list=(
  "$firstargs"
  "--interactive --tty"
  "-v ${appdir}:/opt/app"
  "-p $port:$port -e RAPI_PSGI_PORT=$port"
  "-e RAPI_PSGI_MIN_VERSION=1.3100"
  "-e RAPI_PSGI_FAST_EXIT=1"
);
if [ -n "$extra" ]; then arg_list+=("$extra"); fi

execlist=("$dockercmd")
cmdlist=("$dockercmd \\")
for ((i = 0; i < ${#arg_list[@]}; i++)); do 
  cmdlist+=("  ${arg_list[$i]} \\")
  execlist+=("${arg_list[$i]}")
done
cmdlist+=("$dockerimg")
execlist+=("$dockerimg")

cmd=$(printf "%s\n" "${cmdlist[@]}")
execcmd=$(printf "%s " "${execlist[@]}")


`which docker >& /dev/null`
if [ $? -ne 0 ]; then
  echo -e "WARNING: 'docker' command not found. Have you installed docker on this system yet?"
  dryrun=1
fi


if [[ $dryrun ]]; then  
  echo -e "\n[dry-run] This is the command which would have been ran:\n"
  echo -e "\n$cmd\n"

  exit 0;
else
  if [[ $autopull ]]; then
    echo "--> docker pull $dockerimg"
    `docker pull $dockerimg 1>&2`
  fi
  echo -e "\n-->Running command:\n\n$cmd\n"
  eval "exec $execcmd"
fi




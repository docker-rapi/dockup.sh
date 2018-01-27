#!/usr/bin/env bash
#
#==============================================#
#   dockup.sh                                  #
#   github.com/docker-rapi/dockup.sh           #
    version=0.991                               #
#                                              #
#==============================================#
#


function usage () {
   cat <<EOF
 About dockup.sh:
   dockup.sh is a utility script which is designed to run perl Plack/PSGI 
   applications on-the-fly in a similar manner to 'plackup' but with docker and 
   the rapi/psgi DockerHub image, which is the preferred way to run 
   RapidApp-based applications, although it works for any PSGI application. 
   Like plackup, the target app dir should contain a valid app.psgi file which 
   will be used to start up a dedicated web server on the local system on the 
   supplied port (which defaults to 5000 like plackup).

   All this script does is generate and run a 'docker run' command. It assumes 
   you already have a working installation of docker.

   See:   http://hub.docker.com/r/rapi/psgi/
          http://www.rapi.io


 Usage: 
   dockup.sh [APPDIR]? [-p PORT] [-n] [-c CONTAINER_NAME] [-i IMAGE_NAME]

   Options:
     [APPDIR]   First argument will be used as the app dir; defaults to the pwd
     --help     Display this help screen and exit
     --version  Print the dockup.sh version and exit
     --install  Script copies itself to the supplied path, defaults to /usr/local/bin/

     -p   TCP/IP port so start webserver on (defaults to 5000)
     -c   Custom docker container name, also used as 'hostname'
     -i   Docker image to use, defaults to rapi/psgi

     -n   Dry-run; prints the docker run command which would have been ran without 
          actually running it. This is useful both to be able to see the effect of 
          the options combination as well as to be able to generate docker options 
          to copy and paste and use in a 'docker create' command as well (since 
          docker create and run share most of the same options).

 Examples:
   dockup.sh  # starts the app in the current directory with default options
   
   dockup.sh -p 5002
   dockup.sh /path/to/app -c myapp
   dockup.sh -n -p 5005 -c cool-thing -i my-docker-image

   ./dockup.sh --install  # Installs itself to the local system (/usr/local/bin)

EOF
   exit 0
}

if [ "$1" == "--version" ]; then echo $version; exit 0; fi

echo -e "-- dockup.sh $version --\n"

if [ "$1" == "--help" ]; then usage; fi

if [ "$1" == "--install" ]; then
  echo 'Install mode coming soon';
  exit 0;
fi


###########################################################

# Defaults:
port=5000
dockerimg="rapi/psgi"
dockercmd="docker run"
firstargs="--rm"


# The directory where this script resides:
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Start with the user's current working directory:
appdir=$PWD

# If the current dir doesn't have an app.psgi fallback to the script's parent dir:
if [ ! -f "$appdir/app.psgi" ]; then appdir=$scriptdir; fi

# Or, the user can explicitly provide the app dir as the first argument
if [[ $1 != -* ]]; then
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



while getopts "p:nc:i:" opt; do
  case $opt in
    p) port=$OPTARG;;
    n) dryrun=1;;
    c) dockercmd="docker create"; firstargs="--name $OPTARG --hostname $OPTARG";;
    i) dockerimg=$OPTARG;;
    \?|*) usage;;
  esac
done
shift $((OPTIND -1))

# Catch any rogue words in the arg list that getopts didn't handle
if [ "$#" -gt "0" ]; then
  echo "Invalid extra arguments."
  usage
fi


if [ ! -f "$appdir/app.psgi" ]; then
  echo "Error: Could not determine app dir or no app.psgi file found."
  exit 1
fi

echo "Using PSGI application dir: $appdir"


arg_list=(
  "$firstargs"
  "--interactive --tty"
  "-v ${appdir}:/opt/app"
  "-p $port:$port -e RAPI_PSGI_PORT=$port"
  "-e RAPI_PSGI_MIN_VERSION=1.3004"
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

echo -e "\n$cmd\n"


#if [[ $dryrun ]]; then
#  echo "[dry run]";
#  exit 0;
#fi
#
#eval "exec $execcmd"
#


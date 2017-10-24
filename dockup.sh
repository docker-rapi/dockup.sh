#!/usr/bin/env bash
#
#==============================================#
#   dockup.sh                                  #
#   github.com/docker-rapi/dockup.sh           #
    version=0.99                               #
#                                              #
#==============================================#
#


# Defaults:
port=5000
dockerimg="rapi/psgi"
dockercmd="docker run"
firstargs="--rm"


function usage () {
   cat <<EOF
Usage: dockup.sh [APPDIR]? [-p PORT] [-n] [-c CONTAINER_NAME] [-i IMAGE_NAME]
EOF
   exit 0
}

echo " -- dockup.sh $version --"

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

# Catch any rouge words in the arg list that getopts didn't handle
if [ "$#" -gt "0" ]; then
  echo "Invalid extra arguments."
  usage
fi


if [ ! -f "$appdir/app.psgi" ]; then
  echo "Error: Could not determine app dir or no app.psgi file found."
  exit 1
fi

echo "Using PSGI appplication dir $appdir"


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


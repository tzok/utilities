#! /bin/bash
#
# A set of utility functions

###############################################################################
#   Make an ISO image from a given directory and burn it onto CD/DVD
#   Globals:
#       None
#   Arguments:
#       $1 = path to directory
#       $2 = optional, location of temporary ISO image
#       $3 = optional, device to use for burning
#   Returns:
#       None
#   Notes:
#       By default ISO image will be created in $TMP which could not have
#       enough space
###############################################################################
burn_directory() {
    if [[ ! -d $1 ]]; then
        echo "$1 is not a directory"
        return 1
    fi

    iso=${2:-$(mktemp)}
    device=${3:-/dev/sr0}

    genisoimage -joliet -rational-rock -follow-links -o ${iso} $1
    cdrecord -verbose -dao -eject dev=${device} ${iso}
}

###############################################################################
#   Search for JARs containing the given classname
#   Global:
#       None
#   Arguments:
#       $1 = classname
#       $+ = paths where to look for JARs (recursively)
#   Returns:
#       Paths to JARs that contain the given class
###############################################################################
find_jar() {
    if [[ $# -lt 2 ]]; then
        echo 'Usage: find_jar CLASSNAME PATH-1 [PATH-2 ... PATH-n]'
        return
    fi

    class=$1
    shift
    IFS=$(echo -en '\n\b')
    for file in $(find $@ -L -type f -iname '*.jar'); do
        if unzip -l "$file" | grep $class &>/dev/null; then
            echo "$file"
        fi
    done
    unset IFS
}

###############################################################################
#   Create directories based on file extension, then move files to them.
#   Helps to clean up a messy directory with lots of files
#   Globals:
#       None
#   Arguments:
#       None
#   Returns:
#       None
#   Notes:
#       Works in your current directory!
###############################################################################
order_by_ext() {
    for i in ./*; do 
        if [[ -f "$i" ]]; then
            dir=${i##*.}
            mkdir "$dir" 2>/dev/null
            mv "$i" "$dir"
        fi
    done
 
}

###############################################################################
#   Check what mimetype does a given file have
#   Globals:
#       None
#   Arguments:
#       $1 = path to file
#   Returns:
#       MIME of a given file
###############################################################################
mime() {
    xdg-mime query default $(xdg-mime query filetype $1 | cut -d ';' -f1)
}

###############################################################################
#   Run some process only once, globally for the whole system
#   Globals:
#       None
#   Arguments:
#       $@ = what you want to run once
#   Return:
#       exit code = 1, if the application was not started (other instance is
#       running)
###############################################################################
runonce() {
    ( flock -n 9 && eval $@ ) 9>/tmp/runonce.$1
}


###############################################################################
#   Create a tunnel for a given port or service name
#   Example:    tunnel rsync 80
#               tunnel 22
#               tunnel 9000@9000
#       Globals:
#           TUNNEL_HOST = the host through which the tunnel will be created
#           TUNNEL_TARGET = the target that you wish to get to
#       Arguments:
#           $i = service name or port number
#       Returns:
#           None
###############################################################################
tunnel() {
    if [[ $# -eq 0 ]]; then
        echo 'Usage: TUNNEL_CONFIG= TUNNEL_HOST= TUNNEL_TARGET= tunnel <service|port>'
        return 1
    fi
    if [[ -z $TUNNEL_HOST ]]; then
        echo "TUNNEL_HOST variable not set"
        return 1
    fi
    if [[ -z $TUNNEL_TARGET ]]; then
        echo "TUNNEL_TARGET variable not set"
        return 1
    fi

    local config
    local lport
    local rport
    local i

    for i in $@; do
        if [[ $i =~ ^[[:digit:]]+(@[[:digit:]]+)?$ ]]; then
            rport=$i
        else
            rport=$(awk -v service=$i\
                '$1 == service { split($2, a, "/"); print a[1]; exit }'\
                /etc/services)
            if [[ -z $rport ]]; then
                echo "Service $i not found"
            fi
        fi

        if [[ $rport =~ [[:digit:]]+@[[:digit:]]+ ]]; then
            lport=${rport%@*}
            rport=${rport#*@}
        else
            lport=$(($rport + 10000))
        fi
        echo "$TUNNEL_TARGET:$rport is now on localhost:$lport"
        config="$config -L $lport:$TUNNEL_TARGET:$rport"
    done
    ssh $TUNNEL_CONFIG $config $TUNNEL_HOST
}

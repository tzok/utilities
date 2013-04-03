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


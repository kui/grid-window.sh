#!/bin/bash -eu

#BEGIN
# usage: window-handler.sh [left|right|center]
#
#   a window managing script like `Grid` plugin in compiz.
#
#END

# settings
VERTICAL_GRID_NUM=3
HORIZONTAL_GRID_NUM=6

XDOTOOL="xdotool"
DEBUG=true

main() {
    get_active_window_geometry
    resize '100%' '100%'
    get_active_window_geometry
    resize '60%' '100%'
}

help(){
    local beginl="`grep --line-number '^#BEGIN' $0 | cut -f1 -d':'`"
    local endl="`grep --line-number '^#END' $0 | cut -f1 -d':'`"
    head -n $((endl-1)) "$0" | tail -n $((endl-beginl-1)) | sed 's/^# \?//'
}

p(){
    echo $@
}
d(){
    $DEBUG && p "DEBUG: ${@}"
}
e(){
    p "ERROR: ${@}" >&2
}

get_active_window_geometry(){
    eval `$XDOTOOL getactivewindow getwindowgeometry --shell`
    d "active window geometry: ${WIDTH}x${HEIGHT}+${X}+${Y}"
}

resize(){
    $XDOTOOL getactivewindow windowsize "$1" "$2"
}

$DEBUG && set -x

if [[ $# -eq 0 ]]
then
    help
    exit 1
fi

case $1 in
    left | right | center ) main $1 ;;
    * )
        e "unknown sub-command"
        help ;;
esac

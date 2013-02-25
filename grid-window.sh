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
DEBUG=true

XDOTOOL="xdotool"
WMCTRL="wmctrl"

CURRENT_DESKTOP_NUM=
DESKTOP_WIDTH=
DESKTOP_HEIGHT=
ACTIVE_WINDOW_WIDTH=
ACTIVE_WINDOW_HIGHT=

main() {
    get_desktop_size
    # get_active_window_geometry
    # resize '100%' '100%'
    # get_active_window_geometry
    # resize '60%' '100%'
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

get_active_desktop(){
    CURRENT_DESKTOP_NUM="`"$XDOTOOL" get_desktop`"
}

get_desktop_size(){
    get_desktop_size_with_wmctrl || get_desktop_size_with_xdotool
}

get_desktop_size_with_wmctrl(){
    get_active_desktop
   local dsize="`"$WMCTRL" -d | grep "^$CURRENT_DESKTOP_NUM" |\
                  sed --quiet 's/.* \([0-9]\+x[0-9]\+\) .*/\1/p'`"

   [ -z "$dsize" ] && d "cannot get desktop size with wmctrl" && return 1

   DESKTOP_WIDTH="`echo $dsize | cut -dx -f1`"
   DESKTOP_HEIGHT="`echo $dsize | cut -dx -f2`"

   d "$FUNCNAME: width=${DESKTOP_WIDTH}, height=${DESKTOP_HEIGHT}"
}

get_desktop_size_with_xdotool(){
    get_current_window_size
    resize '100%' '100%'
    get_active_window_geometry
}

get_current_window_size(){
    get_active_window_geometry
    ACTIVE_WINDOW_WIDTH=$WIDTH
    ACTIVE_WINDOW_HIGHT=$HIGHT
}

get_active_window_geometry(){
    eval `"$XDOTOOL" getactivewindow getwindowgeometry --shell`
    d "active window geometry: ${WIDTH}x${HEIGHT}+${X}+${Y}"
}

resize(){
    "$XDOTOOL" getactivewindow windowsize "$1" "$2"
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

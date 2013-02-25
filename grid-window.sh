#!/bin/bash -eu

#BEGIN
# usage: grid-window.sh [left|right|center]
#
#   a window managing script like `Grid` plugin in compiz.
#
#END

# settings
HORIZONTAL_GRID_NUM=6
HORIZONTAL_GRID_MIN_NUM=2
HORIZONTAL_GRID_MIN_NUM=6
XDOTOOL="xdotool"
WMCTRL="wmctrl"
DEBUG=true
set -x # verbose output

# vals
DESKTOP_WIDTH=
DESKTOP_HEIGHT=
CURRENT_WINDOW_WIDTH=
CURRENT_WINDOW_HEIGHT=
CURRENT_WINDOW_X=
CURRENT_WINDOW_Y=

main() {
    #prepare
    get_desktop_size
    get_current_window_geometry


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

get_desktop_size(){
    eval "`\"$XDOTOOL\" search --maxdepth 0 \"\" getwindowgeometry --shell 2>/dev/null`"
    DESKTOP_WIDTH=$WIDTH
    DESKTOP_HEIGHT=$HEIGHT
    unset WIDTH HEIGHT X Y

    assert_empty "$DESKTOP_WIDTH" "$DESKTOP_HEIGHT"
    d "$FUNCNAME: ${DESKTOP_WIDTH}x${DESKTOP_HEIGHT}"
}

get_current_window_geometry(){
    get_active_window_geometry
    CURRENT_WINDOW_WIDTH=$WIDTH
    CURRENT_WINDOW_HEIGHT=$HEIGHT
    CURRENT_WINDOW_X=$X
    CURRENT_WINDOW_Y=$Y
    unset WIDTH HEIGHT X Y

    assert_empty "$CURRENT_WINDOW_WIDTH" "$CURRENT_WINDOW_HEIGHT" \
        "$CURRENT_WINDOW_X" "$CURRENT_WINDOW_Y"
    d "$FUNCNAME: ${CURRENT_WINDOW_WIDTH}x${CURRENT_WINDOW_HEIGHT}+\
${CURRENT_WINDOW_X}+${CURRENT_WINDOW_Y}"
}

get_active_window_geometry(){
    eval `"$XDOTOOL" getactivewindow getwindowgeometry --shell`
    d "$FUNCNAME: ${WIDTH}x${HEIGHT}+${X}+${Y}"
}

resize(){
    "$XDOTOOL" getactivewindow windowsize "$1" "$2"
}

assert_empty(){
    for str in "$@"
    do
        [[ -z "$str" ]] && return 1
    done
    return 0
}

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

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
HORIZONTAL_GRID_MAX_NUM=6
XDOTOOL="xdotool"
WMCTRL="wmctrl"
DEBUG=true
set -x # verbose output

# vals
DIRECTION=
DESKTOP_WIDTH=
DESKTOP_HEIGHT=
CURRENT_WINDOW_WIDTH=
CURRENT_WINDOW_HEIGHT=
CURRENT_WINDOW_X=
CURRENT_WINDOW_Y=
NEXT_WINDOW_WIDTH=
NEXT_WINDOW_HEIGHT=
NEXT_WINDOW_X=
NEXT_WINDOW_Y=

main() {
    #prepare
    DIRECTION=$1
    get_desktop_size
    get_current_window_geometry
    get_next_window_geometry

    apply_next_window_geometry $NEXT_WINDOW_WIDTH $NEXT_WINDOW_HEIGHT \
        $NEXT_WINDOW_X $NEXT_WINDOW_Y
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
    eval "`\"$XDOTOOL\" search --maxdepth 0 \"\" \
                        getwindowgeometry --shell 2>/dev/null`"
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

get_next_window_geometry(){
    get_next_window_width
    get_next_window_height
    get_next_window_x
    get_next_window_y
    assert_empty "$NEXT_WINDOW_WIDTH" "$NEXT_WINDOW_HEIGHT" \
        "$NEXT_WINDOW_X" "$NEXT_WINDOW_Y"
    d "$FUNCNAME: ${NEXT_WINDOW_WIDTH}x${NEXT_WINDOW_HEIGHT}+\
${NEXT_WINDOW_X}+${NEXT_WINDOW_Y}"
}

get_next_window_width(){
    local grid_interval=$((DESKTOP_WIDTH/HORIZONTAL_GRID_NUM))
    local next_width_threshold=$((CURRENT_WINDOW_WIDTH + grid_interval / 2))

    NEXT_WINDOW_WIDTH=$((grid_interval * HORIZONTAL_GRID_MIN_NUM))
    while [[ $NEXT_WINDOW_WIDTH -lt $next_width_threshold ]] \
          && [[ $NEXT_WINDOW_WIDTH -lt $DESKTOP_WIDTH ]]
    do NEXT_WINDOW_WIDTH=$((NEXT_WINDOW_WIDTH + grid_interval))
    done

    # back to min grid
    # if [[ $NEXT_WINDOW_WIDTH -ge $DESKTOP_WIDTH ]]
    # then NEXT_WINDOW_WIDTH=$((grid_interval * HORIZONTAL_GRID_MIN_NUM))
    # fi

    d "$FUNCNAME: NEXT_WINDOW_WIDTH=$NEXT_WINDOW_WIDTH"
}

get_next_window_height(){
    NEXT_WINDOW_HEIGHT=$DESKTOP_HEIGHT
}

get_next_window_x(){
    case $DIRECTION in
        left)   NEXT_WINDOW_X=0 ;;
        right)  NEXT_WINDOW_X=$((DESKTOP_WIDTH - NEXT_WINDOW_WIDTH)) ;;
        center) NEXT_WINDOW_X=$(((DESKTOP_WIDTH - NEXT_WINDOW_WIDTH) / 2)) ;;
    esac
}

get_next_window_y(){
    NEXT_WINDOW_Y=0
}

apply_next_window_geometry(){
    "$XDOTOOL" getactivewindow windowsize $1 $2 windowmove $3 $4
}

assert_empty(){
    for str in "$@"
    do [[ -z "$str" ]] && return 1
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
        e "unknown direction: $1"
        help ;;
esac

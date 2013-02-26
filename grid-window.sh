#!/bin/bash -eu

#BEGIN
# usage: grid-window.sh [left|right|center]
#
#   A grid window managing script like `Grid` plugin in compiz.
#   Use with xmodmap or something keyboard base louncher.
#
#END

# settings
HORIZONTAL_GRID_NUM=6
HORIZONTAL_GRID_MIN_NUM=2
HORIZONTAL_GRID_MAX_NUM=6
XDOTOOL='xdotool'
XDOTOOL_TIMEOUT='0.3'
DEBUG=true
# set -x # verbose output flag

# vals
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
DIRECTION=
GRID_INTERVAL=

main() {
    #prepare
    DIRECTION=$1
    get_desktop_size
    get_grid_interval
    get_current_window_geometry

    # resize and move
    get_next_window_geometry
    apply_next_window_geometry
    update_applied_next_window_geometry

    # back to min grid size, when you cannot apply the next window geometry
    if is_not_move && is_not_resized && is_max_grid_size
    then
        d "back to min grid size"
        get_min_grid_window_geometry
        apply_min_grid_window_geomery
    fi
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
w(){
    p "WARN: ${@}"
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

get_grid_interval(){
    GRID_INTERVAL=$((DESKTOP_WIDTH/HORIZONTAL_GRID_NUM))
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
    local next_width_threshold=$((CURRENT_WINDOW_WIDTH + GRID_INTERVAL / 2))

    NEXT_WINDOW_WIDTH=$((GRID_INTERVAL * HORIZONTAL_GRID_MIN_NUM))
    while [[ $NEXT_WINDOW_WIDTH -lt $next_width_threshold ]] \
        && [[ $NEXT_WINDOW_WIDTH -lt $DESKTOP_WIDTH ]]
    do NEXT_WINDOW_WIDTH=$((NEXT_WINDOW_WIDTH + GRID_INTERVAL))
    done

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
    # TODO do not use `timeout`
    #      use busy loop to wait until window geometry is changed
    if ! timeout $XDOTOOL_TIMEOUT "$XDOTOOL" getactivewindow \
        windowmove $NEXT_WINDOW_X $NEXT_WINDOW_Y \
        windowsize --sync $NEXT_WINDOW_WIDTH $NEXT_WINDOW_HEIGHT
    then w "$FUNCNAME: operation timeout"
    fi
}

update_applied_next_window_geometry(){
    get_active_window_geometry
    NEXT_WINDOW_WIDTH=$WIDTH
    NEXT_WINDOW_HEIGHT=$HEIGHT
    NEXT_WINDOW_X=$X
    NEXT_WINDOW_Y=$Y
    unset WIDTH HEIGHT X Y

    assert_empty "$NEXT_WINDOW_WIDTH" "$NEXT_WINDOW_HEIGHT" \
        "$NEXT_WINDOW_X" "$NEXT_WINDOW_Y"
    d "$FUNCNAME: ${NEXT_WINDOW_WIDTH}x${NEXT_WINDOW_HEIGHT}+\
${NEXT_WINDOW_X}+${NEXT_WINDOW_Y}"
}

is_not_move(){
    [[ $NEXT_WINDOW_X -eq $CURRENT_WINDOW_X ]] \
        && [[ $NEXT_WINDOW_Y -eq $CURRENT_WINDOW_Y ]]
}

is_not_resized(){
    [[ $NEXT_WINDOW_WIDTH -eq $CURRENT_WINDOW_WIDTH ]] \
        && [[ $NEXT_WINDOW_HEIGHT -eq $CURRENT_WINDOW_HEIGHT ]]
}

is_max_grid_size(){
    [[ $((NEXT_WINDOW_WIDTH + (GRID_INTERVAL / 2))) -ge $DESKTOP_WIDTH ]]
}

get_min_grid_window_geometry(){
    get_min_grid_window_width
    get_min_grid_window_height
    get_next_window_x
    get_next_window_y
}

get_min_grid_window_width(){
    NEXT_WINDOW_WIDTH=$((GRID_INTERVAL * HORIZONTAL_GRID_MIN_NUM))
}

get_min_grid_window_height(){
    NEXT_WINDOW_HEIGHT=$DESKTOP_HEIGHT
}

apply_min_grid_window_geomery(){
    "$XDOTOOL" getactivewindow \
        windowsize $NEXT_WINDOW_WIDTH $NEXT_WINDOW_HEIGHT \
        windowmove $NEXT_WINDOW_X $NEXT_WINDOW_Y
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
    exit 0
fi

case $1 in
    left | right | center ) main $1 ;;
    * )
        e "unknown direction: $1"
        help ;;
esac

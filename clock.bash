#!/usr/bin/env bash
# -----------------------------------------------------------
TITLE="Terminal Clock"
AUTHOR="S. Widmer"
EMAIL="sery@solnet.ch"
VERSION="v0.1"
LICENSE="GNU GPLv3+"
# -----------------------------------------------------------


# default color (red)
COLOR="red"

# map color names -> ANSI codes (0-15 supported -> 30-37,90-97)
declare -A _COLORS=(
    [black]=30 [red]=31 [green]=32 [yellow]=33 [blue]=34 [magenta]=35 [cyan]=36 [white]=37
    [bright_black]=90 [bright_red]=91 [bright_green]=92 [bright_yellow]=93 [bright_blue]=94 [bright_magenta]=95 [bright_cyan]=96 [bright_white]=97
)

# function: set COLOR_ESC from $COLOR (supports names, 0-15, ANSI codes 30-37/90-97, #RRGGBB, and R,G,B)
set_color_escape() {
    local val="$COLOR"

    # hex #RRGGBB
    if [[ "$val" == \#* ]]; then
        local h=${val#'#'}
        if [[ ! $h =~ ^[0-9A-Fa-f]{6}$ ]]; then
            printf "Invalid color value: %s\n" "$val" >&2
            exit 1
        fi
        local r=$((16#${h:0:2}))
        local g=$((16#${h:2:2}))
        local b=$((16#${h:4:2}))
        COLOR_ESC="\e[38;2;${r};${g};${b}m"
        return
    fi

    # rgb "R,G,B" (0-255)
    if [[ "$val" =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]; then
        local r=${BASH_REMATCH[1]}
        local g=${BASH_REMATCH[2]}
        local b=${BASH_REMATCH[3]}
        for comp in "$r" "$g" "$b"; do
            if (( comp < 0 || comp > 255 )); then
                printf "Invalid RGB component: %s\n" "$comp" >&2
                exit 1
            fi
        done
        COLOR_ESC="\e[38;2;${r};${g};${b}m"
        return
    fi

    # numeric: 0-15 -> map to 30..37 / 90..97; also accept 30-37 or 90-97 directly
    if [[ "$val" =~ ^[0-9]+$ ]]; then
        local n=$val
        if (( n >= 0 && n <= 15 )); then
            local code
            if (( n < 8 )); then code=$((30 + n)); else code=$((90 + n - 8)); fi
            COLOR_ESC="\e[${code}m"
            return
        elif (( (n >= 30 && n <= 37) || (n >= 90 && n <= 97) )); then
            COLOR_ESC="\e[${n}m"
            return
        fi
        printf "Unknown numeric color: %s\n" "$val" >&2
        exit 1
    fi

    # named colors (case-insensitive)
    local key="${val,,}"
    if [[ -n "${_COLORS[$key]}" ]]; then
        COLOR_ESC="\e[${_COLORS[$key]}m"
        return
    fi

    printf "Unknown color: %s\n" "$val" >&2
    exit 1
}

# default style (80). Accept --style=70 or --style=80
STYLE=80
while [[ $# -gt 0 ]]; do
    case "$1" in
        --style=*)
            val="${1#--style=}"
            val="${val,,}"  # lowercase for case-insensitive matching
            case "$val" in
                50|e-13b) STYLE=50 ;;
                51|e-13b-simple) STYLE=51 ;;
                55|nixie) STYLE=55 ;;
                60|ocr-a) STYLE=60 ;;
                61|ocr-a-simple) STYLE=61 ;;
                70|data-70) STYLE=70 ;;
                71|data-70-simple) STYLE=71 ;;
                72|segment|7-segment) STYLE=72 ;;
                78|vt100) STYLE=78 ;;
                83|vt220) STYLE=83 ;;
                87|vt320) STYLE=87 ;;
                90|modern) STYLE=90 ;;
                80|default) STYLE=80 ;;
                *)
                    printf "Unknown style: %s\nUse '%s --help' for help\n\n" "$val" "$(basename "$0")"
                    exit 1 ;;
            esac
            shift ;;
        --color=*)
            COLOR="${1#--color=}"
            shift ;;
        -h|--help) printf '\nChoose one of the following options:'
           printf '\n  --style=50 or --style=E-13B \t\tMagnetic MICR E-13B font'
           printf '\n  --style=51 or --style=E-13B-simple \tas above but blocks only version'
           printf '\n  --style=55 or --style=NIXIE \t\tnixie tube font'
           printf '\n  --style=60 or --style=OCR-A \t\tOCR-A font'
           printf '\n  --style=61 or --style=OCR-A-SIMPLE \tas above but blocks only version'
           printf '\n  --style=70 or --style=DATA-70 \ta futuristic font'
           printf '\n  --style=71 or --style=DATA-70-SIMPLE \tas above blocks only version'
           printf '\n  --style=72 or --style=7-SEGMENT \tseven segment display font'
           printf '\n  --style=78 or --VT100 \t\tVT100 font'
           printf '\n  --style=80 or --default \t\tdefault 80ies font'
           printf '\n  --style=83 or --VT220 \t\tVT220 font'
           printf '\n  --style=87 or --VT320 \t\tVT320 font'
           printf '\n  --style=90 or --MODERN \t\tmodern font'

           printf '\n\n  --color=<color> \t\tSet display color (default: red)\n'
           printf '\nSupported:\n1. named colors: \n%s' "$(printf '%s ' "${!_COLORS[@]}")"
           printf '\n\n2. numeric 0-15\n\n3. ANSI codes 30-37/90-97\n\n4. hex #RRGGBB\n\n5. R,G,B (0-255)\n\n'
           printf "Example: %s --style=70 --color=red\n\n" "$(basename "$0")"; exit 0 ;;
        *) printf "Unknown option: %s\nUse '%s --help' for help\n\n" "$1" "$(basename "$0")"; exit 1 ;;
        #*) break ;;
    esac
done

# compute COLOR_ESC (escape sequence used to color the output)
set_color_escape

# Define digit representations for style 70ies (inspired by "Data 70 font")
declare -A D

if [[ "$STYLE" -eq 50 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █    █\n █    █\n █▄▄▄▄█'
    D[1]=$'   ██  \n    █  \n    █  \n   ████\n   ████'
    D[2]=$'  ▀▀▀▀█\n      █\n  █▀▀▀▀\n  █    \n  █▄▄▄▄'
    D[3]=$'  ▀▀▀█ \n     █ \n  ▀▀▀█▄\n     ██\n  ▄▄▄██'
    D[4]=$' ██    \n ██    \n ██    \n ██▄▄██\n     ██'
    D[5]=$' █▀▀▀▀ \n █     \n ▀▀▀▀█ \n     █ \n ▄▄▄▄█ '
    D[6]=$' █▀▀█  \n █     \n █     \n █▀▀▀▀█\n █▄▄▄▄█'
    D[7]=$' █▀▀▀█ \n ▀  ◢◤ \n   ◢◤  \n   █   \n   █   '
    D[8]=$' █▀▀▀█ \n █   █ \n◢█▀▀▀█◣\n██   ██\n██▄▄▄██'
    D[9]=$' █▀▀▀▀█\n █    █\n ▀▀▀▀██\n     ██\n     ██'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 51 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █    █\n █    █\n █▄▄▄▄█'
    D[1]=$'   ██  \n    █  \n    █  \n   ████\n   ████'
    D[2]=$'  ▀▀▀▀█\n      █\n  █▀▀▀▀\n  █    \n  █▄▄▄▄'
    D[3]=$'  ▀▀▀█ \n     █ \n  ▀▀▀█▄\n     ██\n  ▄▄▄██'
    D[4]=$' ██    \n ██    \n ██    \n ██▄▄██\n     ██'
    D[5]=$' █▀▀▀▀ \n █     \n ▀▀▀▀█ \n     █ \n ▄▄▄▄█ '
    D[6]=$' █▀▀█  \n █     \n █     \n █▀▀▀▀█\n █▄▄▄▄█'
    D[7]=$' █▀▀▀█ \n ▀  ▗▘ \n   ▗▘  \n   █   \n   █   '
    D[8]=$' █▀▀▀█ \n █   █ \n▗█▀▀▀█▖\n██   ██\n██▄▄▄██'
    D[9]=$' █▀▀▀▀█\n █    █\n ▀▀▀▀██\n     ██\n     ██'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 55 ]]; then
    D[0]=$' ▄▀▀▀▄ \n█     █\n█     █\n█     █\n ▀▄▄▄▀ '
    D[1]=$'    █  \n    █  \n    █  \n    █  \n    █  '
    D[2]=$'  ▄▀▀▄ \n ▀    █\n   ▄▄▀ \n ▄▀    \n █▄▄▄▄▄'
    D[3]=$' ▀▀▀▀▀█\n    ▄▀ \n     ▀▄\n      █\n ▀▄▄▄▀ '
    D[4]=$'    ▄█ \n  ▄▀ █ \n▄▀   █ \n▀▀▀▀▀█▀\n     █ '
    D[5]=$' █▀▀▀▀ \n █▄▄▄  \n ▀   ▀▄\n      █\n ▀▄▄▄▀ '
    D[6]=$'   ▄▀  \n ▄█▄▄  \n▄▀   ▀▄\n█     █\n ▀▄▄▄▀ '
    D[7]=$' ▀▀▀▀▀█\n     █ \n    █  \n   █   \n  █    '
    D[8]=$' ▄▀▀▀▄ \n▀▄   ▄▀\n ▄▀▀▀▄ \n█     █\n ▀▄▄▄▀ '
    D[9]=$' ▄▀▀▀▄ \n█     █\n▀▄   ▄▀\n  ▀█▀  \n ▄▀    '
    D[:]=$'  \n ▄\n  \n ▄\n  '
    D[.]=$'  \n  \n  \n  \n ▄'
elif [[ "$STYLE" -eq 60 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █    █\n █    █\n █▄▄▄▄█'
    D[1]=$' ▀▀█   \n   █   \n   █   \n   █ ▄ \n ▄▄█▄█ '
    D[2]=$' ▀▀▀▀▀█\n      █\n █▀▀▀▀▀\n █     \n █▄▄▄▄▄'
    D[3]=$' ▀▀▀▀▀█\n      █\n  ▀▀▀▀█\n      █\n ▄▄▄▄▄█'
    D[4]=$' █   ▄ \n █   █ \n █▄▄▄█▄\n     █ \n     █ '
    D[5]=$'  █▀▀▀ \n  █    \n  ▀▀▀█ \n     █ \n █▄▄▄█ '
    D[6]=$' █▀    \n █     \n █     \n █▀▀▀█ \n █▄▄▄█ '
    D[7]=$' █▀▀▀█ \n    ◢◤ \n   ◢◤  \n   █   \n   █   '
    D[8]=$'  █▀█  \n  █ █  \n █▀▀▀█ \n █   █ \n █▄▄▄█ '
    D[9]=$' █▀▀▀█ \n █   █ \n ▀▀▀▀█ \n     █ \n    ▄█ '
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 61 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █    █\n █    █\n █▄▄▄▄█'
    D[1]=$' ▀▀█   \n   █   \n   █   \n   █ ▄ \n ▄▄█▄█ '
    D[2]=$' ▀▀▀▀▀█\n      █\n █▀▀▀▀▀\n █     \n █▄▄▄▄▄'
    D[3]=$' ▀▀▀▀▀█\n      █\n  ▀▀▀▀█\n      █\n ▄▄▄▄▄█'
    D[4]=$' █   ▄ \n █   █ \n █▄▄▄█▄\n     █ \n     █ '
    D[5]=$'  █▀▀▀ \n  █    \n  ▀▀▀█ \n     █ \n █▄▄▄█ '
    D[6]=$' █▀    \n █     \n █     \n █▀▀▀█ \n █▄▄▄█ '
    D[7]=$' █▀▀▀█ \n    ▗▘ \n   ▗▘  \n   █   \n   █   '
    D[8]=$'  █▀█  \n  █ █  \n █▀▀▀█ \n █   █ \n █▄▄▄█ '
    D[9]=$' █▀▀▀█ \n █   █ \n ▀▀▀▀█ \n     █ \n    ▄█ '
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 70 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █   ◢█\n █   ██\n █▄▄▄██'
    D[1]=$'    █  \n    █  \n   ◢█  \n   ██  \n   ██  '
    D[2]=$' █▀▀▀▀█\n      █\n ▄▄▄▄▄█\n ██    \n ██▄▄▄▄'
    D[3]=$' █▀▀▀█ \n     █ \n  ▀▀▀█◣\n     ██\n █▄▄▄██'
    D[4]=$' █   █ \n █   █ \n █   █ \n ▀▀▀██▀\n    ██ '
    D[5]=$' █▀▀▀▀ \n █     \n ▀▀▀▀██\n     ██\n █▄▄▄██'
    D[6]=$' █▀▀▀▀█\n █     \n █▀▀▀██\n █   ██\n █▄▄▄██'
    D[7]=$' ▀▀▀▀▀█\n      █\n     ◢█\n     ██\n     ██'
    D[8]=$'  █▀▀█ \n  █  █ \n ◢▀▀▀█◣\n █   ██\n █▄▄▄██'
    D[9]=$' █▀▀▀▀█\n █    █\n █    █\n ▀▀▀▀██\n     ██'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 71 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █   ▗█\n █   ██\n █▄▄▄██'
    D[1]=$'    █  \n    █  \n   ▗█  \n   ██  \n   ██  '
    D[2]=$' █▀▀▀▀█\n      █\n ▄▄▄▄▄█\n ██    \n ██▄▄▄▄'
    D[3]=$' █▀▀▀█ \n     █ \n  ▀▀▀█▖\n     ██\n █▄▄▄██'
    D[4]=$' █   █ \n █   █ \n █   █ \n ▀▀▀██▀\n    ██ '
    D[5]=$' █▀▀▀▀ \n █     \n ▀▀▀▀██\n     ██\n █▄▄▄██'
    D[6]=$' █▀▀▀▀█\n █     \n █▀▀▀██\n █   ██\n █▄▄▄██'
    D[7]=$' ▀▀▀▀▀█\n      █\n     ▗█\n     ██\n     ██'
    D[8]=$'  █▀▀█ \n  █  █ \n ▗▀▀▀█▖\n █   ██\n █▄▄▄██'
    D[9]=$' █▀▀▀▀█\n █    █\n █    █\n ▀▀▀▀██\n     ██'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
    D[.]=$'   \n   \n   \n   \n ██'
elif [[ "$STYLE" -eq 72 ]]; then
    D[0]=$' █▀▀▀▀█\n █    █\n █    █\n █    █\n █▄▄▄▄█'
    D[1]=$'    █  \n    █  \n    █  \n    █  \n    █  '
    D[2]=$' ▀▀▀▀▀█\n      █\n █▀▀▀▀▀\n █     \n █▄▄▄▄▄'
    D[3]=$' ▀▀▀▀▀█\n      █\n  ▀▀▀▀█\n      █\n ▄▄▄▄▄█'
    D[4]=$' █    █\n █    █\n █▄▄▄▄█\n      █\n      █'
    D[5]=$' █▀▀▀▀▀\n █     \n ▀▀▀▀▀█\n      █\n ▄▄▄▄▄█'
    D[6]=$' █▀▀▀▀▀\n █     \n █▀▀▀▀█\n █    █\n █▄▄▄▄█'
    D[7]=$' ▀▀▀▀▀█\n      █\n      █\n      █\n      █'
    D[8]=$' █▀▀▀▀█\n █    █\n █▀▀▀▀█\n █    █\n █▄▄▄▄█'
    D[9]=$' █▀▀▀▀█\n █    █\n ▀▀▀▀▀█\n      █\n ▄▄▄▄▄█'
    D[:]=$'  \n ▄\n  \n ▄\n  '
    D[.]=$'  \n  \n  \n  \n ▄'
elif [[ "$STYLE" -eq 78 ]]; then
    D[0]=$'\n ▄▀▀▀▄ \n█     █\n▀▄   ▄▀\n  ▀▀▀  '
    D[1]=$'\n  ▄█   \n ▀ █   \n   █   \n ▀▀▀▀▀ '
    D[2]=$'\n▄▀▀▀▀▄ \n   ▄▄▄▀\n▄▀▀    \n▀▀▀▀▀▀▀'
    D[3]=$'\n▀▀▀▀▀█▀\n   ▄█▄ \n▄     █\n ▀▀▀▀▀ '
    D[4]=$'\n   ▄█  \n ▄▀ █  \n▀▀▀▀█▀▀\n    ▀  '
    D[5]=$'\n█▀▀▀▀▀▀\n█▄▀▀▀▀▄\n▄     █\n ▀▀▀▀▀ '
    D[6]=$'\n ▄▀▀▀▀▄\n█ ▄▄▄▄ \n█▀    █\n ▀▀▀▀▀ '
    D[7]=$'\n▀▀▀▀▀▀█\n    ▄▀ \n  ▄▀   \n ▀     '
    D[8]=$'\n▄▀▀▀▀▀▄\n▀▄▄▄▄▄▀\n█     █\n ▀▀▀▀▀ '
    D[9]=$'\n▄▀▀▀▀▄ \n▀▄▄▄▄▀█\n▄    ▄▀\n ▀▀▀▀  '
    D[:]=$'\n ▄▄ \n ▀▀ \n ██ \n    '
    D[.]=$'\n    \n    \n ▄▄ \n ▀▀ '
elif [[ "$STYLE" -eq 90 ]]; then
    D[0]=$'  ▄▀▀▄ \n █    █\n █    █\n █    █\n  ▀▄▄▀ '
    D[1]=$'   ▄█  \n ▄▀ █  \n    █  \n    █  \n    █  '
    D[2]=$'  ▄▀▀▄ \n ▀    █\n    ▄▀ \n  ▄▀   \n █▄▄▄▄▄'
    D[3]=$' ▄▀▀▀▄ \n     ▄▀\n  ▀▀▀▄ \n      █\n ▀▄▄▄▀ '
    D[4]=$'    ▄█ \n  ▄▀ █ \n █▄▄▄█▄\n     █ \n     █ '
    D[5]=$' █▀▀▀▀ \n █     \n ▀▀▀▀▄ \n      █\n ▀▄▄▄▀ '
    D[6]=$'  ▄▀▀▄ \n █     \n █▄▀▀▄ \n █    █\n  ▀▄▄▀ '
    D[7]=$' ▀▀▀▀▀█\n     █ \n    █  \n   █   \n  █    '
    D[8]=$'  ▄▀▀▄ \n ▀▄  ▄▀\n  ▄▀▀▄ \n █    █\n  ▀▄▄▀ '
    D[9]=$'  ▄▀▀▄ \n █    █\n  ▀▄▄▀█\n      █\n ▀▄▄▄▀ '
    D[:]=$'  \n ▄\n  \n ▄\n  '
    D[.]=$'  \n  \n  \n  \n ▄'
elif [[ "$STYLE" -eq 83 ]]; then
    D[0]=$'\n ▄▀▀▀▄ \n█     █\n▀▄   ▄▀\n  ▀▀▀  '
    D[1]=$'\n  ▄█   \n ▀ █   \n   █   \n ▀▀▀▀▀ '
    D[2]=$'\n▄▀▀▀▀▀▄\n   ▄▄▄▀\n▄▀▀    \n▀▀▀▀▀▀▀'
    D[3]=$'\n▀▀▀▀▀█▀\n   ▄█▄ \n▄     █\n ▀▀▀▀▀ '
    D[4]=$'\n   ▄█  \n ▄▀ █  \n▀▀▀▀█▀▀\n    ▀  '
    D[5]=$'\n█▀▀▀▀▀▀\n█▄▀▀▀▀▄\n▄     █\n ▀▀▀▀▀ '
    D[6]=$'\n ▄▀▀▀▀ \n█ ▄▄▄▄ \n█▀    █\n ▀▀▀▀▀ '
    D[7]=$'\n▀▀▀▀▀▀█\n    ▄▀ \n  ▄▀   \n  ▀    '
    D[8]=$'\n▄▀▀▀▀▀▄\n▀▄▄▄▄▄▀\n█     █\n ▀▀▀▀▀ '
    D[9]=$'\n▄▀▀▀▀▀▄\n▀▄▄▄▄▀█\n     ▄▀\n ▀▀▀▀  '
    D[:]=$'\n ▄▄ \n ▀▀ \n ██ \n    '
    D[.]=$'\n    \n    \n ▄▄ \n ▀▀ '
elif [[ "$STYLE" -eq 87 ]]; then
    D[0]=$'    ██   \n   █  █  \n  ██  ██ \n  ██  ██ \n  ██  ██ \n   █  █  \n    ██   '
    D[1]=$'██   ██\n    ██ \n    ██ \n    ██ \n    ██ '
    D[2]=$' ██████\n     ██\n ██████\n ██    \n ██████'
    D[3]=$' ██████\n     ██\n ██████\n     ██\n ██████'
    D[4]=$' ██  ██\n ██  ██\n ██████\n     ██\n     ██'
    D[5]=$' ██████\n ██    \n ██████\n     ██\n ██████'
    D[6]=$' ██████\n ██    \n ██████\n ██  ██\n ██████'
    D[7]=$' ██████\n     ██\n     ██\n     ██\n     ██'
    D[8]=$' ██████\n ██  ██\n ██████\n ██  ██\n ██████'
    D[9]=$' ██████\n ██  ██\n ██████\n     ██\n ██████'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
# Define digit representations for style 80ies
else
    D[0]=$' ██████\n ██  ██\n ██  ██\n ██  ██\n ██████'
    D[1]=$'    ██ \n    ██ \n    ██ \n    ██ \n    ██ '
    D[2]=$' ██████\n     ██\n ██████\n ██    \n ██████'
    D[3]=$' ██████\n     ██\n ██████\n     ██\n ██████'
    D[4]=$' ██  ██\n ██  ██\n ██████\n     ██\n     ██'
    D[5]=$' ██████\n ██    \n ██████\n     ██\n ██████'
    D[6]=$' ██████\n ██    \n ██████\n ██  ██\n ██████'
    D[7]=$' ██████\n     ██\n     ██\n     ██\n     ██'
    D[8]=$' ██████\n ██  ██\n ██████\n ██  ██\n ██████'
    D[9]=$' ██████\n ██  ██\n ██████\n     ██\n ██████'
    D[:]=$'   \n ██\n   \n ██\n   '
    D[.]=$'   \n   \n   \n   \n ██'
fi

# Hide cursor (civis:cursor_invisible) and ensure it is restored on exit (cnorm:cursor_normal)
tput civis
trap 'tput cnorm; printf "\n"; exit' INT TERM EXIT ERR HUP

# Clear once, then update in-place
printf '\033[2J'    # clear screen
prev=""

prev_cols=$(tput cols)
prev_lines=$(tput lines)

while true; do
    # detect terminal resize and force a redraw when it happens
    cur_cols=$(tput cols)
    cur_lines=$(tput lines)
    resized=0
    if (( cur_cols != prev_cols || cur_lines != prev_lines )); then
        prev_cols=$cur_cols
        prev_lines=$cur_lines
        resized=1
        prev=""                  # force redraw even if time hasn't changed
        printf '\033[2J'         # clear screen to avoid artifacts
    fi

    now=$(date +"%H:%M:%S")
    if [[ "$now" != "$prev" ]] || (( resized )); then
        prev="$now"
        # prepare 5 rows for time
        rows=("" "" "" "" "")
        for ((i=0;i<${#now};i++)); do
            ch=${now:i:1}
            digit="${D[$ch]}"
            readarray -t lines <<< "$digit"
            rows[0]+="${lines[0]} "
            rows[1]+="${lines[1]} "
            rows[2]+="${lines[2]} "
            rows[3]+="${lines[3]} "
            rows[4]+="${lines[4]} "
        done

        # prepare 5 rows for date (DD.MM.YYYY)
        date_str=$(date +"%d.%m.%Y")
        date_rows=("" "" "" "" "")
        for ((i=0;i<${#date_str};i++)); do
            ch=${date_str:i:1}
            digit="${D[$ch]}"
            readarray -t lines <<< "$digit"
            date_rows[0]+="${lines[0]} "
            date_rows[1]+="${lines[1]} "
            date_rows[2]+="${lines[2]} "
            date_rows[3]+="${lines[3]} "
            date_rows[4]+="${lines[4]} "
        done

        # move cursor to top-left and print (no whole-screen clear)
        printf '\033[H'
        printf '\n'   # small top padding
        printf '%b%b%b\n' "$COLOR_ESC" " ${rows[0]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${rows[1]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${rows[2]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${rows[3]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${rows[4]}" $'\e[0m'
        # separator line
        cols=$(tput cols)
        printf '\n%b' "$COLOR_ESC"
        printf -v __bar '%*s' "$cols" ''
        __bar=${__bar// /━}
        printf '%s' "$__bar"
        printf '%b\n\n' $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${date_rows[0]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${date_rows[1]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${date_rows[2]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${date_rows[3]}" $'\e[0m'
        printf '%b%b%b\n' "$COLOR_ESC" " ${date_rows[4]}" $'\e[0m'

        # draw inverted statusbar on the bottom
        cols=$(tput cols)
        lines=$(tput lines)
        right_msg="| Q: Quit " # use ASCII pipe to avoid flickering
        left_msg="${TITLE} ${VERSION}  ${AUTHOR}  ${EMAIL}  ${LICENSE}"
        left_len=${#left_msg}
        right_len=${#right_msg}
        pad=$((cols - left_len - right_len))
        if (( pad < 1 )); then
            # truncate left_msg to make room for right_msg and at least one space
            max_left=$((cols - right_len - 1))
            (( max_left < 0 )) && max_left=0
            left_msg="${left_msg:0:max_left}"
            left_len=${#left_msg}
            pad=$((cols - left_len - right_len))
            (( pad < 0 )) && pad=0
        fi
        # move to last row and print reversed full-width status line: left_msg + padding + right_msg
        printf '%s' "$(tput cup $((lines-1)) 0)$(tput rev)${left_msg}$(printf '%*s' "$pad" '')${right_msg}$(tput sgr0)"
    fi

    # wait a short time and check for a keypress; quit on 'q' or 'Q'
    key=
    if read -rsn1 -t 0.1 key; then
        if [[ $key == 'q' || $key == 'Q' || $key == $'\e' ]]; then
            tput cnorm
            printf '\033[2J'    # clear screen
            exit 0
        fi
    fi
done

## Log levels, in the order of increasing verbosity
readonly FATAL=1
readonly ERROR=2
readonly INFO=3
readonly WARN=4
readonly DEBUG=5

## ANSI escape codes for colors
readonly RED="\033[0;31m"
readonly BOLD_RED="\033[1;31m"
readonly BLUE="\033[1;34m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly WHITE="\033[0;37m"
readonly CYAN="\033[0;36m"
readonly WHITE_UNDERLINE="\033[4;37m"
readonly NC="\033[0m"    # No color

## Default verbosity
VERBOSITY=$WARN

## Exit code for the script 'check_gg_readiness.sh'
SCRIPT_EXIT_CODE=0

## Variables to track warnings and fatals.
WARNINGS=""
FATALS=""
WARNINGS_COUNT=0
FATALS_COUNT=0

validate_and_set_verbosity() {
    local verbosity="$1"

    case "$verbosity" in
        FATAL )
            VERBOSITY=$FATAL
            ;;

        ERROR )
            VERBOSITY=$ERROR
            ;;

        INFO )
            VERBOSITY=$INFO
            ;;

        WARN )
            VERBOSITY=$WARN
            ;;

        DEBUG )
            VERBOSITY=$DEBUG
            ;;

        * )
            fatal "Unknown --log-level '$verbosity'."
            fatal "--log-level should be one of:"
            fatal "FATAL, ERROR, INFO, WARN and DEBUG"
            exit 1
            ;;
    esac
}

set_verbosity() {
    local verbosity="$1"

    validate_and_set_verbosity "$verbosity"
    if [ $VERBOSITY -eq $DEBUG ]
    then
        set -x
    fi
}

log() {
    local log_level="$1"
    local color="$2"
    local message="$3"
    local new_line="$4"

    if [ $log_level -le $VERBOSITY ]
    then
        $PRINTF "${color}$message${NC}"
        if [ $new_line -eq 1 ]
        then
            $PRINTF "\n"
        fi
    fi
}

label() {
    local message="$1"
    log $INFO $CYAN "$message" 0
}

header() {
    local message="$1"
    log $INFO $BLUE "$message" 1
}

underline() {
    local message="$1"
    log $INFO $WHITE_UNDERLINE "$message" 0
}

fatal() {
    local message="$1"
    log $FATAL $BOLD_RED "$message" 1
    SCRIPT_EXIT_CODE=1
}

error() {
    local message="$1"
    log $ERROR $RED "$message" 1
    SCRIPT_EXIT_CODE=1
}

debug() {
    local message="$1"
    log $DEBUG $WHITE "$message" 1
}

info() {
    local message="$1"
    log $INFO $WHITE "$message" 1
}

success() {
    local message="$1"
    log $INFO $GREEN "$message" 1
}

warn() {
    local message="$1"
    log $WARN $YELLOW "$message" 1
}

wrap_good() {
    label "$1: "
    success "$2"
}

wrap_warn() {
    label "$1: "
    warn "$2"
}

wrap_bad() {
    label "$1: "
    error "$2"
}

wrap_info() {
    label "$1: "
    info "$2"
}

add_to_warnings() {
    local message="$1"

    WARNINGS_COUNT=$($EXPR $WARNINGS_COUNT + 1)
    WARNINGS="$WARNINGS\n$WARNINGS_COUNT. $message\n"
}

add_to_fatals() {
    local message="$1"

    SCRIPT_EXIT_CODE=1
    FATALS_COUNT=$($EXPR $FATALS_COUNT + 1)
    FATALS="$FATALS\n$FATALS_COUNT. $message\n"
}

print_results() {
    local message
    local ggc_version="$1"

    info ""
    info "------------------------------------Results-----------------------------------------"
    if [ "$WARNINGS_COUNT" -ne 0 ]
    then
        underline "Warnings:"
        warn "$WARNINGS"
    fi

    if [ "$FATALS_COUNT" -ne 0 ]
    then
        underline "Missing requirements:"
        fatal "$FATALS"
    fi

    info ""
    info "----------------------------------Exit status---------------------------------------"
    if [ $SCRIPT_EXIT_CODE -ne 0 ]
    then
        message="The device seems to be missing one or more of the required"
        message="$message dependencies for\nGreengrass version $ggc_version."
        message="$message Refer to the 'Missing requirements' section under\n'Results'"
        message="$message for details.\n"
        fatal "$message"
    else
        message="You can now proceed to installing the Greengrass core software"
        message="$message on the device.\nPlease reach out to the AWS Greengrass"
        message="$message support if issues arise.\n"
        info "$message"
    fi

    exit $SCRIPT_EXIT_CODE
}
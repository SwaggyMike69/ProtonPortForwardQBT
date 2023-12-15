#!/command/with-contenv bash
# shellcheck shell=bash

# We need to start the script this way, otherwise the rest of the container
# will not be able to initialize, due to the infinite loop we configured
# in the script this one calls.

SCRIPT_DIR="/usr/local/bin"
source "$SCRIPT_DIR/portForward.sh" &

exit 0

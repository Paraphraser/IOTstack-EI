#!/bin/bash
set -e

# are we running as root?
if [ "$(id -u)" = '0' ] ; then

   echo "[IOTstack] starting udevd"
   /lib/systemd/systemd-udevd --daemon

   # conform directory
   chown -R "$PUID:$PGID" "$HOME_DIR"

   echo "[IOTstack] container launched. To interact, do:"
   echo "  docker exec -it -u ${EI_UNAME} edge-impulse bash"

fi

# away we go
exec "$@"

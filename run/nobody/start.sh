#!/bin/bash

# set password for user 'nobody' - used to access the mineos web ui
echo -e "${MINEOS_PASSWORD}\n${MINEOS_PASSWORD}" | passwd nobody

# create path to store created minecraft servers and configs,
# which is referenced in /etc/mineos.conf.
mkdir -p /config/mineos

# run mineos-node in foreground (blocking)
echo "[info] Starting MineOS-node..."
cd /opt/mineos && node webui.js

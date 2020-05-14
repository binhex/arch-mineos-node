#!/bin/bash

# create path to store created minecraft servers and configs,
# which is referenced in /etc/mineos.conf.
mkdir -p /config/mineos/logs /config/mineos/certs /config/mineos/config

# copy default self-signed certs
if [[ ! -f '/config/mineos/certs/mineos.key' ]]; then
	cp '/etc/ssl/certs/mineos.key' '/config/mineos/certs/mineos.key'
fi

if [[ ! -f '/config/mineos/certs/mineos.crt' ]]; then
	cp '/etc/ssl/certs/mineos.crt' '/config/mineos/certs/mineos.crt'
fi

# if config doesnt exist then copy default config and then softlink back
if [[ ! -f '/config/mineos/config/mineos.conf' ]]; then
	cp '/etc/mineos.conf-backup' '/config/mineos/config/mineos.conf'
fi
ln -fs '/config/mineos/config/mineos.conf' '/etc/mineos.conf'

# run mineos-node in foreground (blocking)
echo "[info] Starting MineOS-node..."
cd /opt/mineos && node webui.js

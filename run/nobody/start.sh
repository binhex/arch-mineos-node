#!/bin/bash

# set file access control list so subsequent created directories allow read and write by 'other' users
# required as this container must run as user 'root' group 'root'
setfacl -R -d -m o::rwx /config

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

# run mineos-node in background (non-blocking)
echo "[info] Starting MineOS-node..."
cd /opt/mineos && /home/nobody/.nvm/versions/node/v8.17.0/bin/node ./service.js start
echo "[info] MineOS-node started"

# set file and folder permissions so that 'other' users have read and write access to /config (recursively).
# required as this container must run as user 'root' group 'root'
chmod -R 777 /config && cat

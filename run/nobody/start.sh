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

# run mineos-node in background (non-blocking)
echo "[info] Starting MineOS-node..."
cd /opt/mineos && /home/nobody/.nvm/versions/node/v8.17.0/bin/node ./service.js start
echo "[info] MineOS-node started"

# if chmod exclusions defined then process
if [[ ! -z "${CHMOD_EXCLUDE_PATHS}" ]]; then

	# split comma separated string into array from CHMOD_EXCLUDE_PATHS env variable
	IFS=',' read -ra chmod_exclude_paths_array <<< "${CHMOD_EXCLUDE_PATHS}"

	# process chmod exclude paths in the array
	for chmod_exclude_paths_item in "${chmod_exclude_paths_array[@]}"; do
		chmod_exclude_paths+="-o -path ${chmod_exclude_paths_item} -prune "
	done

	# strip '-o ' option for first exclude, as this is a binary or
	chmod_exclude_paths="${chmod_exclude_paths:3}"

	# construct full command line for find
	chmod_cli="find /config ${chmod_exclude_paths} -o -exec chmod 777 {} +"

	# run recursive chmod with exclusions, this is required as mineos-node runs as user 'root' group 'root'
	echo "[info] Running chmod for /config with exclusions..."
	eval "${chmod_cli}"

else

	echo "[info] Running chmod for /config (no exclusions)..."
	chmod -R 777 /config

fi

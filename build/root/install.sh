#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# detect image arch
####

OS_ARCH=$(cat /etc/os-release | grep -P -o -m 1 "(?=^ID\=).*" | grep -P -o -m 1 "[a-z]+$")
if [[ ! -z "${OS_ARCH}" ]]; then
	if [[ "${OS_ARCH}" == "arch" ]]; then
		OS_ARCH="x86-64"
	else
		OS_ARCH="aarch64"
	fi
	echo "[info] OS_ARCH defined as '${OS_ARCH}'"
else
	echo "[warn] Unable to identify OS_ARCH, defaulting to 'x86-64'"
	OS_ARCH="x86-64"
fi

# pacman packages
####

# define pacman packages
pacman_packages="git rdiff-backup screen rsync npm node-gyp base-devel jre11-openjdk-headless"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="nvm"

# call aur install script (arch user repo)
source aur.sh

# custom
####

# use nvm to install specific version of nodejs (v8) required by mineos
echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
source ~/.bashrc
nvm install v8

# download mineos-node from github and use npm to install
mkdir -p /opt/mineos
cd /opt/mineos
git clone https://github.com/hexparrot/mineos-node.git .
chmod +x generate-sslcert.sh
./generate-sslcert.sh
npm install

# set path to store servers and config
sed -i -e "s~base_directory = '/var/games/minecraft'~base_directory = '/config/mineos/games'~g" '/opt/mineos/mineos.conf'
sed -i -e "s~ssl_private_key = '/etc/ssl/certs/mineos.key'~ssl_private_key = '/config/mineos/certs/mineos.key'~g" '/opt/mineos/mineos.conf'
sed -i -e "s~ssl_certificate = '/etc/ssl/certs/mineos.crt'~ssl_certificate = '/config/mineos/certs/mineos.crt'~g" '/opt/mineos/mineos.conf'

# copy config to correct location - note '-backup' as we softlink
# back once copied in install.sh
cp '/opt/mineos/mineos.conf' '/etc/mineos.conf-backup'

# container perms
####

# /etc required to allow user 'nobody' to create softlink from
# /config/mineos/config/mineos.conf to /etc/mineos.conf
chmod 777 /etc

# define comma separated list of paths 
install_paths="/opt/mineos,/etc/ssl/certs,/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different 
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export WEBUI_PASSWORD=$(echo "${WEBUI_PASSWORD}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${WEBUI_PASSWORD}" ]]; then
	echo "[info] WEBUI_PASSWORD defined as '${WEBUI_PASSWORD}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] WEBUI_PASSWORD not defined,(via -e WEBUI_PASSWORD), defaulting to 'mineos'" | ts '%Y-%m-%d %H:%M:%.S'
	export WEBUI_PASSWORD="mineos"
fi

# set password for user 'nobody' - used to access the mineos web ui
echo -e "${WEBUI_PASSWORD}\n${WEBUI_PASSWORD}" | passwd nobody 1>&- 2>&-
EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh

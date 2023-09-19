#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from build arg, stripped of build ver using string manipulation
RELEASETAG="${1//-[0-9][0-9]/}"

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

# get target arch from Dockerfile argument
TARGETARCH="${2}"

# pacman packages
####

# define pacman packages
pacman_packages="git rdiff-backup screen rsync npm node-gyp base-devel jre8-openjdk-headless jre11-openjdk-headless jre-openjdk-headless"

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

# get latest java version for package 'jre-openjdk-headless'
latest_java_version=$(pacman -Qi jre-openjdk-headless | grep -P -o -m 1 '^Version\s*: \K.+' | grep -P -o -m 1 '^[0-9]+')

export JAVA_VERSION=$(echo "${JAVA_VERSION}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${JAVA_VERSION}" ]]; then
	echo "[info] JAVA_VERSION defined as '${JAVA_VERSION}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] JAVA_VERSION not defined,(via -e JAVA_VERSION), defaulting to Java version 'latest'" | ts '%Y-%m-%d %H:%M:%.S'
	export JAVA_VERSION="latest"
fi

if [[ "${JAVA_VERSION}" == "8" ]]; then
	ln -fs '/usr/lib/jvm/java-8-openjdk/jre/bin/java' '/usr/bin/java'
	archlinux-java set java-8-openjdk/jre
elif [[ "${JAVA_VERSION}" == "11" ]]; then
	ln -fs '/usr/lib/jvm/java-11-openjdk/bin/java' '/usr/bin/java'
	archlinux-java set java-11-openjdk
elif [[ "${JAVA_VERSION}" == "latest" ]]; then
	ln -fs "/usr/lib/jvm/java-${latest_java_version}-openjdk/bin/java" '/usr/bin/java'
	archlinux-java set java-${latest_java_version}-openjdk
else
	echo "[warn] Java version '${JAVA_VERSION}' not valid, defaulting to Java version 'latest" | ts '%Y-%m-%d %H:%M:%.S'
	ln -fs "/usr/lib/jvm/java-${latest_java_version}-openjdk/bin/java" '/usr/bin/java'
	archlinux-java set java-${latest_java_version}-openjdk
fi

EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/local/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh

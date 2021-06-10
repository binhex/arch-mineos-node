**Application**

[MineOS-node](https://github.com/hexparrot/mineos-node)

**Description**

MineOS is a server front-end to ease managing Minecraft administrative tasks. This iteration using Node.js aims to enhance previous MineOS scripts (Python-based), by leveraging the event-triggering, asyncronous model of Node.JS and websockets.

This allows the front-end to provide system health, disk and memory usage, and logging in real-time.

The front-end also allows you to create and manage a multitude of Java based servers, including Mojang Java, Spigot, Nukkit, Forge and many other popular minecraft server types. You can create archives and restore points of your world's straight from the web ui, meaning loss of important playtime is minimised.

**Build notes**

GitHub master branch of MineOS-node for Linux.

**Usage**
```
docker run -d \
    --net="bridge" \
    --name=<container name> \
    -p <host port for mineos web ui>:8443/tcp \
    -p <host port range for minecraft servers>:25565-25575 \
    -v <host path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBUI_PASSWORD=<password used to authenticate with web ui> \
    -e JAVA_VERSION=<8|11|16> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for root> \
    -e PGID=<gid for root> \
    binhex/arch-mineos-node
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access application**

`https://<host ip>:<host port for mineos web ui>`

Login to the web ui is via username 'nobody' with password as specified via env var value for 'WEBUI_PASSWORD'.

**Example**
```
docker run -d \
    --net="bridge" \
    --name=mineos-node \
    -p 8443:8443/tcp \
    -p 25565-25575:25565-25575 \
    -v /apps/docker/mineos-node:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBUI_PASSWORD=mineos \
    -e JAVA_VERSION=11 \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-mineos-node
```

**Notes**

Please note this container **MUST** run as user 'root', group 'root' (PUID=0 PGID=0), otherwise you will be unable to authenticate via the web ui.
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/92533-support-binhex-mineos-node/)
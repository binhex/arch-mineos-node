**Application**

[MineOS-node](https://github.com/hexparrot/mineos-node)

**Description**

MineOS is a server front-end to ease managing Minecraft administrative tasks. This iteration using Node.js aims to enhance previous MineOS scripts (Python-based), by leveraging the event-triggering, asyncronous model of Node.JS and websockets.

This allows the front-end to provide system health, disk and memory usage, and logging in real-time.

**Build notes**

GitHub master branch of MineOS-node for Linux.

**Usage**
```
docker run -d \
    --net="bridge" \
    --name=<container name> \
    -p <host port for mineos web ui>:8443/tcp \
    -p <host port range for minecraft servers>:25565-25570 \
    -v <host path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBUI_PASSWORD=<password used to authenticate with web ui> \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for root> \
    -e PGID=<gid for root> \
    binhex/arch-mineos-node
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access application**

Login to the web ui is via username 'nobody' with password as specifed via env var value for 'WEBUI_PASSWORD'.

**Example**
```
docker run -d \
    --net="bridge" \
    --name=mineos-node \
    -p 8443:8443/tcp \
    -p 25565-25570:25565-25570 \
    -v /apps/docker/mineos-node:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBUI_PASSWORD=mineos \
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

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/84905-support-binhex-minecraftbedrockserver/)
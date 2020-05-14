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
    -p <host port>:8443/tcp \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e UMASK=<umask for created files> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    binhex/arch-mineos-node
```

Please replace all user variables in the above command defined by <> with the correct values.

**Example**
```
docker run -d \
    --net="bridge" \
    --name=mineos-node \
    -p 8443:8443/tcp \
    -v /apps/docker/mineos-node:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-mineos-node
```

**Notes**

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/84905-support-binhex-minecraftbedrockserver/)

# Configuration for hotio qbitTorrentVPN container

This guide provides step-by-step instructions on how to configure your hotio QBT container to forward protonvpn ports. 

## Unraid Setup

### 1. Copy Scripts

First, copy the scripts to a safe location on the host which is hosting your container.

### 2. Edit Container Settings

Next, configure your container settings in Unraid:

- Go to the Unraid UI and edit your QBT container.
- Scroll to the bottom and click **Add another Path, Port, Variable**.
- Configure each script as detailed below:

#### Start Port Forwarding Script

```
Config Type: Path
Name: startportforward
Container Path: /etc/cont-init.d/startPortForward.sh
Host Path: /path/to/startPortForward.sh
```

#### Port Forwarding Script

```
Config Type: Path
Name: portForward
Container Path: /usr/local/bin/portForward.sh
Host Path: /path/to/portForward.sh
```

### 3. Restart Container

After restarting your container, check the logs for QBT to see information about the ports, and to confirm that everything is working as intended.

### 4. Script Configuration

The scripts are set to retrieve necessary packages for updating ports. If the script fails to retrieve the natpmp package, perform the following:

- Download manually from [this link](https://github.com/yimingliu/py-natpmp/archive/master.tar.gz).
- Copy it to your server and map it as follows, and restart the container:

```
Config Type: Path
Name: natpmp
Container Path: /usr/local/bin/master.tar.gz
Host Path: /path/to/master.tar.gz
```

# Docker Compose Setup ( Credits to elysium6497 )

### 1. Copy Scripts

First, copy the scripts to a safe location on the host which is hosting your container.

### 2. Edit Your Docker Compose

Add the following lines to the volumes block of qbittorrent in your compose file.

```
      - /path/to/your/startPortForward.sh:/etc/cont-init.d/startPortForward.sh
      - /path/to/your/portForward.sh:/usr/local/bin/portForward.sh
      # - /path/to/your/master.tar.gz:/usr/local/bin/master.tar.gz # if required
```

### 3. Restart Container

"Compose Up" or docker-compose up -d


### Docker Compose Example

In this example, startPortForward.sh, portForward.sh, and py-natpmp-master.tar.gz are saved in the qbittorrent appdata directory in qbittorrent\portforward.

```
  qbittorrent:
    container_name: qbittorrent
    image: ghcr.io/hotio/qbittorrent
    ports:
      - "8080:8080"
      - "8118:8118"
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
      - VPN_ENABLED=true
      - VPN_LAN_NETWORK=192.168.1.0/24
      - VPN_CONF=wg0
      - VPN_ADDITIONAL_PORTS
      - PRIVOXY_ENABLED=false
    volumes:
      - /mnt/user/appdata/qbittorrent:/config
      - /mnt/user/data/torrents:/data/torrents
      - /mnt/user/appdata/qbittorrent/portforward/startPortForward.sh:/etc/cont-init.d/startPortForward.sh
      - /mnt/user/appdata/qbittorrent/portforward/portForward.sh:/usr/local/bin/portForward.sh
      - /mnt/user/appdata/qbittorrent/portforward/master.tar.gz:/usr/local/bin/master.tar.gz
    cap_add:
      - NET_ADMIN
    dns:
      - 1.1.1.1
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=1
    restart: unless-stopped
```

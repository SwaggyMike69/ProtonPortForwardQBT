
# Configuration for hotio qbitTorrentVPN container

This guide provides step-by-step instructions on how to configure your hotio QBT container to forward protonvpn ports.  This is written for unraid in mind, but the scripts will work for any environment.

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

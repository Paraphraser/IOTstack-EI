# IOTstack-EI

Temporary experimental repo for bringing Edge-Impulse into IOTstack.

> Please focus on the word *temporary*. This repo will go away once experiments are complete and a Pull Request can be formalised for bringing Edge-Impulse into IOTstack.

## Setup

1. Assumes an up-to-date copy of [IOTstack](https://github.com/SensorsIot/IOTstack) exists on your Raspberry Pi. If not, clone IOTstack:
	
	```
	$ git clone https://github.com/SensorsIot/IOTstack.git ~/IOTstack
	```

2. Assumes master branch:

	```
	$ cd ~/IOTstack
	$ git switch master
	$ git pull origin master
	```
	
3. Move to the templates directory:

	```
	$ cd ~/IOTstack/.templates
	```
	
4. Clone this repo:

	```
	$ git clone https://github.com/Paraphraser/IOTstack-EI.git edge-impulse
	```
	
5. Fetch a local copy of `setup_12.x`:

	```
	$ cd ./edge-impulse
	$ wget https://deb.nodesource.com/setup_12.x
	```

## Build the local image

1. Be in the correct directory (assumed throughout).

	```
	$ cd ~/IOTstack
	```

2. Add the service definition to your compose file. You have two options:

	* **EITHER** run the menu:
	
		```
		$ ./menu.sh
		```
		
		then select `edge-impulse` from the menu.
		
	* **OR** append the service definition to your compose file by hand:
	
		```
		$ sed -e "s/^/  /" .templates/edge-impulse/service.yml >>docker-compose.yml
		```

3. Bring up the container:

	```
	$ docker-compose up -d edge-impulse
	```

	This builds the container and sets it running. Assuming no obvious errors in the Dockerfile output, you should expect to see this kind of output:
	
	```
	$ docker ps
	CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS     NAMES
	f99199c7149d   iotstack-edge-impulse   "docker-entrypoint.s…"   5 minutes ago    Up 5 minutes             edge-impulse

	$ docker logs edge-impulse
	[IOTstack] starting udevd
	Starting version 247.3-7+deb11u1
	[IOTstack] container launched. To interact, do:
	  docker exec -it -u edge-impulse edge-impulse bash
	```

## Service definition

```
edge-impulse:
  container_name: edge-impulse
  build:
    context: ./.templates/edge-impulse/.
    args:
    - LINUX_DISTRO=debian
    - DISTRO_VERSION=latest
  restart: unless-stopped
  environment:
  - TZ=${TZ:-Etc/UTC}
  - UDEV=1
# - EI_HOST=
  network_mode: host
  volumes:
  - /dev:/dev:ro
  - ./volumes/edge-impulse:/home/edge-impulse
  devices:
  - /dev:/dev
  privileged: true
```

Notes:

* `TZ=${TZ:-Etc/UTC}` assumes you have defined your timezone in the `~/IOTstack/.env` file. If not, you can initialise it like this:

	```
	$ echo "TZ=Australia/Sydney" >>~/IOTstack/.env
	```

* `EI_HOST=` appears to mean the Edge Impulse development server instance you wish to use (from `edge-impulse-linux --help`)
* The examples given [here](https://docs.edgeimpulse.com/docs/development-platforms/officially-supported-cpu-gpu-targets/raspberry-pi-4#install-with-docker) specify:
	- `UDEV=1` but the meaning is unclear.
	- host mode networking. It is not clear why but IT has been implemented.
	- a volume mapping of `/dev:/dev` which grants the container access to the whole of the Raspberry Pi's `/dev`. For now, that access has been curtailed by appending the `:ro` (read-only) flag.
	- A similar comment could probably be made about the `devices` mapping but that has been left as-is.
	- `privileged: true` appears to be required. Omitting it returns the error:

		```
		Failed to set receive buffer size for device monitor, ignoring: Operation not permitted
		```

### other environment variables

The following environment variables are supported:

* `PUID`, default value 1000, the user ID of the user inside the container
* `PGID`, default value 1000, the group ID of the user inside the container
* `EI_UNAME`, default value "edge-impulse", the name of the user inside the container

## Getting started

### persistent store

The examples given [here](https://docs.edgeimpulse.com/docs/development-platforms/officially-supported-cpu-gpu-targets/raspberry-pi-4#install-with-docker) do not include a persistent store. This implies any changes will evaporate each time the container is recreated.

To try to cater for data that should persist between invocations, the Dockerfile defines a user named `edge-impulse` and associates that user with UID=1000, GID=1000. This corresponds with the UID+GID of the default user on the Raspberry Pi (usually `pi`).

Inside the container, the `edge-impulse` user's home directory is at the path:

```
/home/edge-impulse
```

The service definition maps that folder to the persistent store at:

```
~/IOTstack/volumes/edge-impulse
```

Any data created in or below that folder will persist across container invocations.

### getting a shell inside the container

To interact with the running container, do one of the following:

* To run inside the container as the user `edge-impulse`:

	```
	$ docker exec -it -u edge-impulse edge-impulse bash
	edge-impulse@tri-dev:~$
	```
	
	The prompt is:
	
	- `edge-impulse` (the user)
	- `@tri-dev` (the host name - yours will be different)
	- `~` (the home directory)
	- `$` (non-root user) 

* To run inside the container as the root user:

	```
	$ docker exec -it edge-impulse bash
	root@tri-dev:/home/edge-impulse# 
	```

	The prompt is:
	
	- `root ` (the user)
	- `@tri-dev` (the host name - yours will be different)
	- `/home/edge-impulse` (the default working directory)
	- `#` (root user) 

### running `edge-impulse-linux`

At the shell prompt:

```
$ edge-impulse-linux
? What is your user name or e-mail address (edgeimpulse.com)? 
```

To terminate, press <kbd>control</kbd>+<kbd>c</kbd>.

Other commands are:

```
$ edge-impulse-camera-debug
$ edge-impulse-linux-runner
```

### exiting the container shell

To exit the container shell, either press <kbd>control</kbd>+<kbd>d</kbd> or type `exit` and press <kbd>return</kbd>.

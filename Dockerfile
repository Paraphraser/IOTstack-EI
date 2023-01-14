ARG LINUX_DISTRO=debian
ARG DISTRO_VERSION=latest

FROM $LINUX_DISTRO:$DISTRO_VERSION

# re-reference supported arguments and copy to environment vars
ARG LINUX_DISTRO
ARG DISTRO_VERSION
ENV LINUX_DISTRO=${LINUX_DISTRO}
ENV DISTRO_VERSION=${DISTRO_VERSION}

ENV TZ=UTC

RUN set -eux ; \
    apt update ; \
    apt upgrade

# fetch the edge-impulse setup script.
# ADD https://deb.nodesource.com/setup_12.x setup_12.x
COPY setup_12.x /setup_12.x

# run the setup script
RUN bash /setup_12.x

# install other packages
RUN DEBIAN_FRONTEND=noninteractive \
       apt install -y --no-install-recommends \
          gcc \
          g++ \
          make \
          build-essential \
          nodejs \
          sox \
          gstreamer1.0-tools \
          gstreamer1.0-plugins-good \
          gstreamer1.0-plugins-base \
          gstreamer1.0-plugins-base-apps \
          vim \
          v4l-utils \
          usbutils \
          udev \
          tzdata

RUN npm config set user root

RUN npm install edge-impulse-linux -g --unsafe-perm

# cleanup
RUN DEBIAN_FRONTEND=noninteractive \
       apt remove --purge --auto-remove -y; \
    rm -rf /var/lib/apt/lists/*

# we install binaries in
ENV BIN_PATH="/usr/local/bin"

# set up the container start point
ENV ENTRYPOINT_SCRIPT="docker-entrypoint.sh"
COPY ${ENTRYPOINT_SCRIPT} ${BIN_PATH}
RUN chmod 755 ${BIN_PATH}/${ENTRYPOINT_SCRIPT}

# reference supported arguments
ARG PUID
ARG PGID
ARG EI_UNAME

# copy to variables and assign defaults if omitted
ENV PUID=${PUID:-1000}
ENV PGID=${PGID:-1000}
ENV EI_UNAME=${EI_UNAME:-edge-impulse}

# home directory is at
ENV HOME_DIR="/home/${EI_UNAME}"

# define a user to be compatible with a nominated IOTstack user ID
RUN useradd -u ${PUID} -M -d ${HOME_DIR} -s /bin/bash ${EI_UNAME}

# home directory should persist
VOLUME ["${HOME_DIR}"]

# home directory is where the action is
WORKDIR ${HOME_DIR}

# edge-impulse listens to (maybe - this isn't clear)
# EXPOSE 4911

# starting point - self-repair and launch
ENTRYPOINT ["docker-entrypoint.sh"]

# container expects user interaction via docker exec
# the sleep command keeps the container in suspended animation
CMD sleep 365d

# set container metadata
LABEL com.github.SensorsIot.IOTstack.Dockerfile.maintainer="Paraphraser <34226495+Paraphraser@users.noreply.github.com>"
LABEL com.github.SensorsIot.IOTstack.Dockerfile.built-on="${LINUX_DISTRO}:${DISTRO_VERSION}"
LABEL com.github.SensorsIot.IOTstack.Dockerfile.based-on="https://hub.docker.com/r/ubuntu/edge-impulse"

# don't need these variables in the container
ENV LINUX_DISTRO=
ENV DISTRO_VERSION=
ENV BIN_PATH=
ENV ENTRYPOINT_SCRIPT=

# EOF

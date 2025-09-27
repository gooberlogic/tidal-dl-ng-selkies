FROM ubuntu:24.04

ENV WEBUI_USER=admin
ENV WEBUI_PASS=changeme

ENV PUID=1001
ENV PGID=1001

ENV CHMOD_FILE=770
ENV CHMOD_DIR=771

ENV SELKIES_PORT=5577

RUN apt update -y; apt upgrade -y; apt install --no-install-recommends -y jq tar gzip ca-certificates curl libpulse0 wayland-protocols libwayland-dev libwayland-egl1 x11-utils x11-xkb-utils x11-xserver-utils xserver-xorg-core libx11-xcb1 libxcb-dri3-0 libxkbcommon0 libxdamage1 libxfixes3 libxv1 libxtst6 libxext6 xvfb xinit openbox xterm

RUN mkdir /app; cd /app; export SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')"; curl -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-portable-v${SELKIES_VERSION}_amd64.tar.gz" | tar -xzf -; cd /

COPY --from=tianon/gosu /gosu /usr/local/bin/

RUN mkdir -p /etc/X11/xorg.conf.d/
COPY 10-headless.conf /etc/X11/xorg.conf.d/ 

RUN echo "allowed_users = anybody" >> /etc/X11/Xwrapper.config

COPY entrypoint.bash /entrypoint.bash
RUN chmod +x /entrypoint.bash

ENTRYPOINT /entrypoint.bash

FROM ubuntu:24.04

ENV WEBUI_USER=admin
ENV WEBUI_PASS=changeme

ENV PUID=1001
ENV PGID=1001

ENV CHMOD_FILE=770
ENV CHMOD_DIR=771

ENV SELKIES_PORT=5577

ENV SELKIES_TURN_HOST=127.0.0.1
ENV SELKIES_TURN_PROTOCOL=udp
ENV SELKIES_TURN_PORT=3478
ENV TURN_MIN_PORT=10000
ENV TURN_MAX_PORT=10020

RUN apt update -y && apt upgrade -y && \
    # dependencies
    apt install --no-install-recommends -y jq tar gzip ca-certificates curl libpulse0 wayland-protocols \
    libwayland-dev libwayland-egl1 x11-utils x11-xkb-utils x11-xserver-utils xserver-xorg-core libx11-xcb1 \
    libxcb-dri3-0 libxkbcommon0 libxdamage1 libxfixes3 libxv1 libxtst6 libxext6 \
    # extra packages
    xvfb coturn xterm openbox xvfb pipewire pipewire-pulse wireplumber udev dbus-x11 dbus-user-session adwaita-icon-theme xclip \
    # graphics drivers
    mesa-va-drivers libva2 vainfo vdpau-driver-all libvdpau-va-gl1 vdpauinfo mesa-vulkan-drivers vulkan-tools

RUN mkdir /app; mkdir /app/selkies; cd /app/selkies; export SELKIES_VERSION="$(curl -fsSL "https://api.github.com/repos/selkies-project/selkies/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')"; curl -fsSL "https://github.com/selkies-project/selkies/releases/download/v${SELKIES_VERSION}/selkies-gstreamer-portable-v${SELKIES_VERSION}_amd64.tar.gz" | tar -xzf -; cd /

ENV VGL_DISPLAY=egl
RUN cd /tmp && VIRTUALGL_VERSION="$(curl -fsSL "https://api.github.com/repos/VirtualGL/virtualgl/releases/latest" | jq -r '.tag_name' | sed 's/[^0-9\.\-]*//g')" && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    dpkg --add-architecture i386 && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" && \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends "./virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "./virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_amd64.deb" "virtualgl32_${VIRTUALGL_VERSION}_amd64.deb" && \
    chmod -f u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libvglfaker-opencl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so && \
    chmod -f u+s /usr/lib32/libvglfaker.so /usr/lib32/libvglfaker-nodl.so /usr/lib32/libvglfaker-opencl.so /usr/lib32/libdlfaker.so /usr/lib32/libgefaker.so && \
    chmod -f u+s /usr/lib/i386-linux-gnu/libvglfaker.so /usr/lib/i386-linux-gnu/libvglfaker-nodl.so /usr/lib/i386-linux-gnu/libvglfaker-opencl.so /usr/lib/i386-linux-gnu/libdlfaker.so /usr/lib/i386-linux-gnu/libgefaker.so; \
    elif [ "$(dpkg --print-architecture)" = "arm64" ]; then \
    curl -fsSL -O "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    apt-get update && apt-get install -y --no-install-recommends ./virtualgl_${VIRTUALGL_VERSION}_arm64.deb && \
    rm -f "virtualgl_${VIRTUALGL_VERSION}_arm64.deb" && \
    chmod -f u+s /usr/lib/libvglfaker.so /usr/lib/libvglfaker-nodl.so /usr/lib/libdlfaker.so /usr/lib/libgefaker.so; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /var/log/* /tmp/* /var/tmp/*; \
    cd /

COPY --from=tianon/gosu /gosu /usr/local/bin/

ENV DBUS_SYSTEM_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/tmp}/dbus-system-bus"

RUN echo "allowed_users = anybody" >> /etc/X11/Xwrapper.config

COPY entrypoint.bash /entrypoint.bash
RUN chmod +x /entrypoint.bash

ENTRYPOINT /entrypoint.bash

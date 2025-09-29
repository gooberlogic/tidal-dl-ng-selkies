FROM ubuntu:24.04

ENV WEBUI_PORT=5578
ENV WEBUI_USER=admin
ENV WEBUI_PASS=changeme

ENV PUID=1001
ENV PGID=1001

ENV CHMOD_FILE=770
ENV CHMOD_DIR=771

ENV SELKIES_PORT=5577

ENV GTK_THEME=Adwaita:dark
ENV XCURSOR_SIZE=32
ENV XVFB_DPI=115

ENV DBUS_SYSTEM_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/tmp}/dbus-system-bus"

ENV NOTICE="\nNOTICE: "
ENV NOTICE_USER="\nNOTICE: [USER] "
ENV NOTICE_END="...\n"

RUN apt update -y; apt upgrade -y; apt install -y software-properties-common; add-apt-repository ppa:mozillateam/ppa; \
    # selkies dependencies
    apt install --no-install-recommends -y jq tar gzip ca-certificates curl libpulse0 wayland-protocols \
    libwayland-dev libwayland-egl1 x11-utils x11-xkb-utils x11-xserver-utils xserver-xorg-core libx11-xcb1 \
    libxcb-dri3-0 libxkbcommon0 libxdamage1 libxfixes3 libxv1 libxtst6 libxext6 cmake git nodejs npm wget \
    # tidal-dl-ng dependencies
    libxcb-cursor0 python3-pip libxcb-render0-dev libxcb-cursor-dev libxcb1-dev libxcb1 libxcb-util1 \
    libxrender1 libxkbcommon-x11-0 libxcb-keysyms1 libxcb-image0 libxcb-shm0 libxcb-icccm4 libxcb-sync1 \
    libxcb-xfixes0 libxcb-shape0 libxcb-randr0 libxcb-render-util0 python3-dev build-essential libevdev-dev ffmpeg \
    # extra packages
    xvfb xterm openbox xvfb pipewire pipewire-pulse wireplumber udev dbus-x11 dbus-user-session adwaita-icon-theme xclip firefox-esr \
    xdg-utils breeze-cursor-theme feh python3-venv nginx xdotool apache2-utils gnome-themes-extra pulsemixer

RUN mkdir -p /music /data /app

# selkies install latest
RUN cd /app; wget https://github.com/selkies-project/selkies/archive/refs/heads/main.tar.gz; tar -xf main.tar.gz; rm main.tar.gz; cd ./selkies-main; \
    pip install . --break-system-packages --ignore-installed

# selkies frontend
RUN git clone https://github.com/selkies-project/selkies.git /app/src; cd /app/src; cd addons/gst-web-core; npm install; npm run build; cp dist/selkies-core.js ../selkies-dashboard/src; \
    cd ../selkies-dashboard; npm install; npm run build; mkdir dist/src dist/nginx; cp ../universal-touch-gamepad/universalTouchGamepad.js dist/src/; \
    cp ../gst-web-core/nginx/* dist/nginx/; cp -r ../gst-web-core/dist/jsdb dist/; mkdir /app/frontend; cp -ar dist/* /app/frontend

RUN echo "allowed_users = anybody" >> /etc/X11/Xwrapper.config

COPY --from=tianon/gosu /gosu /usr/local/bin/

COPY wallpaper.png /wallpaper.png
RUN chmod +r /wallpaper.png


RUN pip install --upgrade "tidal-dl-ng[gui]" --break-system-packages --ignore-installed

COPY entrypoint.bash /entrypoint.bash
RUN chmod +x /entrypoint.bash

ENTRYPOINT /entrypoint.bash

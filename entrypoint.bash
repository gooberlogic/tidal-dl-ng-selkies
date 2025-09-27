#!/usr/bin/env bash

echo -e "\nNOTICE: Creating user xyz ($PUID, $PGID)...\n"

groupadd -g "$PGID" xyz
useradd -u "$PUID" -g xyz -s /bin/bash -m xyz

echo -e "\nNOTICE: Setting ownership and perms ($CHMOD_FILE, $CHMOD_DIR)...\n"

#chown -R xyz:xyz /app

#find /app -type f -exec chmod $CHMOD_FILE {} \;
#find /app -type d -exec chmod $CHMOD_DIR {} \;

echo -e "\nNOTICE: Setting xinitrc...\n"

echo 'exec openbox-session' > /home/xyz/.xinitrc
mkdir -p /home/xyz/.config/openbox/
echo "xterm" > /home/xyz/.config/openbox/autostart
chmod +x /home/xyz/.xinitrc /home/xyz/.config/openbox/autostart

gosu xyz /bin/bash -s <<'EOF'

echo -e "\nNOTICE: Starting...\n"

cd ~


startx &

export DISPLAY="${DISPLAY:-:0}"
export PIPEWIRE_LATENCY="128/48000"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
export PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
export PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
export PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

/app/selkies-gstreamer/selkies-gstreamer-run --addr=0.0.0.0 --port=${SELKIES_PORT} --enable_https=false --https_cert=/etc/ssl/certs/ssl-cert-snakeoil.pem --https_key=/etc/ssl/private/ssl-cert-snakeoil.key --basic_auth_user=${WEBUI_USER} --basic_auth_password=${WEBUI_PASS} --encoder=x264enc --enable_resize=false

sleep 120m

EOF



#!/usr/bin/env bash

echo -e "\nNOTICE: Setting /etc/turnserver.conf...\n"

cat <<EOF > /etc/turnserver.conf
realm=localhost
external-ip=127.0.0.1

listening-port=${SELKIES_TURN_PORT}
min-port=${TURN_MIN_PORT}
max-port=${TURN_MAX_PORT}

use-auth-secret
static-auth-secret=${WEBUI_PASS}

log-file=stdout
pidfile=/tmp/turnserver.pid
userdb=/tmp/turnserver.db
verbose

allow-loopback-peers
no-cli
no-software-attribute
no-rfc5780
no-stun-backward-compatibility
response-origin-only-with-rfc5780
EOF

chmod 744 /etc/turnserver.conf

echo -e "\nNOTICE: Creating user xyz ($PUID, $PGID)...\n"

groupadd -g "$PGID" xyz
useradd -u "$PUID" -g xyz -s /bin/bash -m xyz

echo -e "\nNOTICE: Setting ownership and perms ($CHMOD_FILE, $CHMOD_DIR)...\n"

#chown -R xyz:xyz /app

#find /app -type f -exec chmod $CHMOD_FILE {} \;
#find /app -type d -exec chmod $CHMOD_DIR {} \;

echo -e "\nNOTICE: Configuring openbox...\n"

mkdir -p /home/xyz/.config/openbox/
echo "xterm" > /home/xyz/.config/openbox/autostart
chmod +x /home/xyz/.config/openbox/autostart

gosu xyz /bin/bash -s <<'EOF'

echo -e "\nNOTICE: Starting...\n"

cd ~

export DISPLAY="${DISPLAY:-:20}"
export PIPEWIRE_LATENCY="128/48000"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
export PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
export PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
export PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

Xvfb "${DISPLAY}" -screen 0 "8192x4096x24" +extension "COMPOSITE" +extension "DAMAGE" +extension "GLX" +extension "RANDR" +extension "RENDER" +extension "MIT-SHM" +extension "XFIXES" +extension "XTEST" +iglx +render -nolisten "tcp" -ac -noreset -shmem &

pipewire &
wireplumber &
pipewire-pulse &

sleep 5

vglrun -d "${VGL_DISPLAY:-egl}" /usr/bin/dbus-launch --exit-with-session openbox-session &
#/usr/bin/dbus-launch --exit-with-session openbox-session &

coturn &

/app/selkies/selkies-gstreamer/selkies-gstreamer-run --addr=0.0.0.0 --port=${SELKIES_PORT} --enable_https=false --https_cert=/etc/ssl/certs/ssl-cert-snakeoil.pem --https_key=/etc/ssl/private/ssl-cert-snakeoil.key --basic_auth_user=${WEBUI_USER} --basic_auth_password=${WEBUI_PASS} --encoder=vp9enc --turn_shared_secret=${WEBUI_PASS} --enable_resize=true   

EOF



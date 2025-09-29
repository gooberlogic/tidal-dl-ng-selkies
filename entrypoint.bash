#!/usr/bin/env bash

echo -e "${NOTICE}Creating user xyz ($PUID, $PGID)${NOTICE_END}"

groupadd -g "$PGID" xyz
useradd -u "$PUID" -g xyz -s /bin/bash -m xyz

echo -e "${NOTICE}Configuring and starting nginx ($WEBUI_PORT, $SELKIES_PORT)${NOTICE_END}"

htpasswd -Bbn "${WEBUI_USER}" "${WEBUI_PASS}" > /etc/nginx/.htpasswd

sed -i 's/^user .*/user xyz xyz;/' /etc/nginx/nginx.conf

cat <<EOF > /etc/nginx/conf.d/selkies.conf
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}
server {
    listen ${WEBUI_PORT};

    location / {
        auth_basic "login required";
        auth_basic_user_file /etc/nginx/.htpasswd;

        root /app/frontend/;
        index index.html;
        try_files \$uri \$uri/ =404;
    }

    location /websocket {
        auth_basic "login required";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://localhost:${SELKIES_PORT}/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 86400;
    }

    location /devmode {
        auth_basic "login required";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://localhost:${SELKIES_PORT}/;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 86400;
    }

    location /files {
        auth_basic "login required";
        auth_basic_user_file /etc/nginx/.htpasswd;

        autoindex on;
    }
}
EOF

mkdir -p /var/log/nginx
nginx &

echo -e "${NOTICE}Settings directory links (/music, /data)${NOTICE_END}"

mkdir -p /home/xyz/.config/
ln -s /music /home/xyz/download
ln -s /data /home/xyz/.config/tidal_dl_ng

rm -rf /usr/share/icons/breeze_cursors
ln -s /usr/share/icons/Breeze_Snow /usr/share/icons/breeze_cursors

echo -e "${NOTICE}Setting ownership and perms ($CHMOD_FILE, $CHMOD_DIR)${NOTICE_END}"

chown -R xyz:xyz /music /data /app/frontend /tmp

find /music /data -type f -exec chmod $CHMOD_FILE {} \;
find /music /data -type d -exec chmod $CHMOD_DIR {} \;

echo -e "${NOTICE}Configuring openbox and other things${NOTICE_END}"

mkdir -p /home/xyz/.config/openbox/
echo "xrdb ~/.Xresources; while true; do /usr/local/bin/tidal-dl-ng-gui; done" > /home/xyz/.config/openbox/autostart

chmod +x /home/xyz/.config/openbox/autostart

cat <<EOF > /home/xyz/.Xresources
Xcursor.theme: Breeze_Snow
*.foreground: #ffffff
*.background: #000000
EOF

mkdir -p "/home/xyz/.config/gtk-3.0/"

cat <<EOF > /home/xyz/.config/gtk-3.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=true
EOF

gosu xyz /bin/bash -s <<'EOF'

echo -e "${NOTICE_USER}Starting Xvfb${NOTICE_END}"

cd ~

export DISPLAY="${DISPLAY:-:20}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
#export PIPEWIRE_LATENCY="128/48000"
#export PIPEWIRE_RUNTIME_DIR="${PIPEWIRE_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-/tmp}}"
#export PULSE_RUNTIME_PATH="${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}"
#export PULSE_SERVER="${PULSE_SERVER:-unix:${PULSE_RUNTIME_PATH:-${XDG_RUNTIME_DIR:-/tmp}/pulse}/native}"

Xvfb "${DISPLAY}" -screen 0 "1920x1080x24" -dpi ${XVFB_DPI} +extension "COMPOSITE" +extension "DAMAGE" +extension "GLX" +extension "RANDR" +extension "RENDER" +extension "MIT-SHM" +extension "XFIXES" +extension "XTEST" +iglx +render -nolisten "tcp" -ac -noreset -shmem &

echo -e "${NOTICE_USER}Starting pipewire${NOTICE_END}"

pipewire &
pipewire-pulse &
wireplumber &

sleep 3

echo -e "${NOTICE_USER}Starting openbox${NOTICE_END}"

/usr/bin/dbus-launch --exit-with-session openbox-session &

feh -bg /wallpaper.png --bg-tile &

echo -e "${NOTICE_USER}Starting selkies${NOTICE_END}"

selkies --audio-enabled=False

EOF

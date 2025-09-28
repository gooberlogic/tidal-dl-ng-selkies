# tidal-dl-ng-selkies

## docker-compose.yml
create example `.env` file:
```bash
TIDALDL_WEBPASS=changeme # openssl rand -hex 15
TIDALDL_ID=1001 # id of user for PUID
MEDIA_ID=1001 # id of group for PGID
```
example `docker-compose.yml`:
```yml
services:
  tidal-dl:
    image: example.com/gooberlogic/tidal-dl-ng-selkies:latest
    container_name: tidal-dl
    restart: no
    environment:
      - WEBUI_USER=admin
      - WEBUI_PASS=${TIDALDL_WEBPASS}
      - PUID=${TIDALDL_ID}
      - PGID=${MEDIA_ID}
      - SELKIES_PORT=5577
    ports:
      - "5577:5577/tcp"
      # uncomment for coturn
      #- "10000-10020:10000-10020/tcp"
      #- "10000-10020:10000-10020/udp"
```
### Environment

| Variable | Default Value | Description |
| -------- | ------- | ----------- |
| WEBUI_USER | admin | self explanitory |
| WEBUI_PASS | changeme | self explanitory |
| PUID | 1001 | process ID of selkies and coturn |
| PGID | 1001 | group process ID of selkies and coturn |
| CHMOD_FILE | 770 | chmod of files in /data and /music dirs |
| CHMOD_DIR | 771 | chmod of dirs in /data and /music dirs |
| SELKIES_PORT | 5577 | port of the selkies webui |
| SELKIES_TURN_PORT | 3478 | coturn internal container port |
| TURN_MIN_PORT | 10000 | coturn starting port in port range |
| TURN_MAX_PORT | 10020 | coturn finishing port in port range |

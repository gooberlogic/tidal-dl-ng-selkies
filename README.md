# tidal-dl-ng-selkies

Docker container to run [tidal-dl-ng](https://github.com/exislow/tidal-dl-ng) and stream the gui to web browser using [selkies](https://github.com/selkies-project/selkies).

![Screenshot](./screenshot.png)

## Docker Compose
```yml
services:
  tidal-dl:
    image: ghcr.io/gooberlogic/tidal-dl:latest
    hostname: tidal-dl
    container_name: tidal-dl
    restart: no
    environment:
      - WEBUI_USER=admin
      - WEBUI_PASS=changeme
      - PUID=1001
      - PGID=1001
      # make connection HTTPS with snakeoil certs
      #- SNAKEOIL_HTTPS=True
    ports:
      - "5578:5578/tcp"
    volumes:
      - "./tidal-dl/config:/data"
      - "./media/music:/music"
      # alternate case
      #- "./media/music:/music/music"
      #- "./media/music_videos:/music/music_videos"
```
Access GUI from web browser: `http://localhost:5578` / `https://localhost:5578`

CLI is also avaliable:
```bash
$ docker exec -it tidal-dl su xyz -c 'cd; bash'
xyz@tidal-dl:~$ tidal-dl-ng
```

#### Notice

- **If `SNAKEOIL_HTTPS` is `False`, a HTTPS reverse proxy will be required for connecting externally.**

- Audio in an unbearable state, disabled in selkies.

- These paths are symlinked within the container:

  - `/data -> /home/xyz/.config/tidal_dl_ng`

  - `/music -> /home/xyz/download`

#### Environment Variables

| Variable | Default Value | Description |
| -------- | ------------- | ----------- |
| `SNAKEOIL_HTTPS` | `False` | make connection HTTPS with snakeoil certs |
| `WEBUI_PORT` | `5578` | port of the selkies frontend |
| `WEBUI_USER` | `admin` | username to frontend |
| `WEBUI_PASS` | `changeme` | password to frontend |
| `PUID` | `1001` | process user ID of selkies and nginx |
| `PGID` | `1001` | process group ID of selkies and nginx |
| `CHMOD_FILE` | `770` | chmod override of files in `/data` and `/music` |
| `CHMOD_DIR` | `771` | chmod override of dirs in `/data` and `/music` |
| `SELKIES_PORT` | `5577` | port of the selkies websocket |
| `XVFB_DPI` | `110` | Xorg DPI, increase/decrease to manage display scaling |

There are more variables provided in `Dockerfile` and [selkies documentation](https://github.com/selkies-project/selkies/tree/main/src#available-settings).

## tidal-dl-ng

#### Preferences
Example tidal-dl-ng preferences:
```
download_base_path: ~/download
format_track: Tracks/{album_artist}/{album_title}/CD {track_volume_num_optional} - {album_track_num}. {artist_name} - {track_title} {track_explicit}
format_album: {album_artist}/{album_title} {album_explicit}/CD {track_volume_num_optional} - {album_track_num}. {artist_name} - {track_title} {track_explicit}
path_binary_ffmpeg: /usr/bin/ffmpeg
```

## License

**This project is licensed under [GNU Affero General Public License v3.0](./LICENSE)**

#### Acknowledgements

- [tidal-dl-ng](https://github.com/exislow/tidal-dl-ng) \[[GNU Affero General Public License v3.0](https://github.com/exislow/tidal-dl-ng/blob/master/LICENSE)\]\
The main software this container was made to run.

- [selkies](https://github.com/selkies-project/selkies) \[[Mozilla Public License 2.0](https://github.com/selkies-project/selkies/blob/main/LICENSE)\]\
Provided main container webui software and various [code references](https://github.com/selkies-project/selkies/tree/main/addons/example) used here.

- [gosu](https://github.com/tianon/gosu) \[[Apache License 2.0](https://github.com/tianon/gosu/blob/master/LICENSE)]\
Allows easily running applications as user rather than root within docker container.

- [docker-baseimage-selkies](https://github.com/linuxserver/docker-baseimage-selkies) \[[GNU General Public License v3.0](https://github.com/linuxserver/docker-baseimage-selkies/blob/master/LICENSE)\]\
Provided various code references used here, like the frontend install and nginx config.

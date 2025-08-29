# Sample configuration files

## For docker

The default logging driver is local-json, which may create rather large files. The output of traefik (the primary responder to inbound traffic) is already redirected to local files beneath docker/logs/, so additional logs could be kept trimmed down by using the `local` log driver instead. Note: takes effect for new containers - existing containers will not be updated.

daemon.json - place in /etc/docker/ or update your existing configuration.

## For logrotate of traefik

As logging for traefik is stored under docker/logs/, a means of rotating these should be in place. This example rotates these files using logrotate and signals traefik to re-open the log file.

traefik-logrotate-example - place in /etc/logrotate.d/

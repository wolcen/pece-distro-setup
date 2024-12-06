ARG PHP_VER=8.3
FROM wodby/drupal-php:${PHP_VER}

ARG UID=1000
ARG GID=1000

WORKDIR /var/www/html
USER ${UID}:${GID}
COPY --chown=${UID}:${GID} . .
USER root
RUN ["composer", "install"]
RUN ["chown", "-R", "wodby:wodby", "/var/www/html"]
USER wodby:wodby
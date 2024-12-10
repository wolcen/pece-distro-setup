ARG PHP_VER=8.3
FROM wodby/drupal-php:${PHP_VER}

ARG UID=1000
ARG GID=1000

WORKDIR /var/www/html
USER ${UID}:${GID}
COPY --chown=${UID}:${GID} . .
USER root

COPY drupal10.settings.php.tmpl /etc/gotpl/

RUN ["composer", "install", "--no-dev", "--optimize-autoloader"]
RUN ["ln", "-s", "/mnt/files/public", "/var/www/html/web/sites/default/files"]
RUN ["ln", "-s", "/mnt/files/private", "/var/www/html/private"]
RUN ["chown", "-R", "wodby:wodby", "/var/www/html"]
USER wodby
RUN ["composer", "clear-cache"]

ARG PHP_VER=8.3
FROM wodby/drupal-php:${PHP_VER}

WORKDIR /var/www/html
COPY . .
USER root

COPY drupal10.settings.php.tmpl /etc/gotpl/

RUN ["composer", "install", "--no-dev", "--optimize-autoloader"]
RUN ["ln", "-s", "/mnt/files/public", "/var/www/html/web/sites/default/files"]
RUN ["ln", "-s", "/mnt/files/private", "/var/www/html/private"]
RUN ["chown", "-R", "wodby:wodby", "/var/www/html"]
USER wodby
RUN ["composer", "clear-cache"]

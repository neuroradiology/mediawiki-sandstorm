#!/bin/bash

mkdir -p /var/opt/wiki
test -e /var/opt/wiki/wiki.sqlite || cp /opt/app/wiki.sqlite /var/opt/wiki/wiki.sqlite
test -e /var/VERSION || echo "1.23.2" > /var/VERSION
[[ "$(cat /var/VERSION)" == "1.24.1" ]] || (cd /opt/app/mediawiki-core && php maintenance/update.php --quick && echo "1.24.1" > /var/VERSION)

# Create a bunch of folders under the clean /var that php, nginx, and mysql expect to exist
mkdir -p /var/lib/nginx
mkdir -p /var/lib/php5/sessions
mkdir -p /var/log
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run

# Spawn mysqld, php
/usr/sbin/php5-fpm --nodaemonize --fpm-config /etc/php5/fpm/php-fpm.conf &
# Wait until mysql and php have bound their sockets, indicating readiness
while [ ! -e /var/run/php5-fpm.sock ] ; do
    echo "waiting for php5-fpm to be available at /var/run/php5-fpm.sock"
    sleep .2
done

# Start nginx.
/usr/sbin/nginx -g "daemon off;"

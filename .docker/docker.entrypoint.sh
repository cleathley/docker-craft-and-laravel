#!/bin/bash

# Allow for mail to be sent out (need to add a domain to localhost) (has to be here after the container has started)
echo "127.0.0.1 localhost.localdomain localhost slave" > /etc/hosts

# Start supervisor (which fires off redis, nginx and php-fpm)
export COMPOSER_ALLOW_SUPERUSER=1; /usr/bin/supervisord -n -c /etc/supervisord.conf

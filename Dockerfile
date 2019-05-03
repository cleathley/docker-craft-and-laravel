FROM ubuntu:16.04

MAINTAINER Chris Leathley <cleathley@thebrandagency.co>

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
ENV COMPOSER_NO_INTERACTION 1

# Set the locale
ENV LANG C.UTF-8

# We are using supervisor, so disable initctl
RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -sf /bin/true /sbin/initctl && \
    mkdir /var/run/sshd && \
    mkdir /run/php

# Update the Software repositories
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y software-properties-common python-software-properties language-pack-en
RUN LC_ALL=en_AU.UTF-8 add-apt-repository -y ppa:ondrej/php;
RUN apt-get update

# Install some helpers, nodejs, php-fpm and nginx from the ubuntu repositorys
RUN apt-get install -y vim curl sudo unzip supervisor inetutils-ping sendmail mailutils \
    telnet mysql-client git rsync
RUN apt-get install -y php7.1 php7.1-gd php7.1-intl php7.1-mbstring php7.1-mysql php7.1-pgsql \
    php7.1-sqlite3 php7.1-cli php7.1-fpm php7.1-curl php7.1-soap php7.1-mcrypt php7.1-zip php7.1-xml \
    php7.1-bcmath php7.1-ldap php-imagick php-redis php-pear imagemagick
RUN apt-get install -y nginx
RUN apt-get install -y redis-server

# Enable the some of the extra php modules which are not enabled as default
RUN phpenmod mcrypt; phpenmod mbstring; phpenmod soap

# Generate a strong key exchange certificate and self signed SSL for 'localhost'
RUN openssl dhparam -out /etc/nginx/dhparams.pem 2048
RUN openssl req -subj '/CN=localhost' -x509 -newkey rsa:4096 -nodes -keyout /etc/nginx/localhost.key -out /etc/nginx/localhost.pem -days 999

# Instal MsSQL (for php7+)
RUN apt-get install -y apt-transport-https ca-certificates && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 && \
    apt-get install -y unixodbc-dev gcc g++ build-essential php7.1-dev && \
    pecl install sqlsrv pdo_sqlsrv && \
    echo extension=pdo_sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini && \
    echo extension=sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/20-sqlsrv.ini && \
    cp /etc/php/7.1/cli/conf.d/20-sqlsrv.ini /etc/php/7.1/fpm/conf.d/ && \
    cp /etc/php/7.1/cli/conf.d/30-pdo_sqlsrv.ini /etc/php/7.1/fpm/conf.d/

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install Node and Gulp
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Tweak redis / nginx and php settings
RUN echo "daemonize no" >> /etc/redis/redis.conf

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.1/fpm/php-fpm.conf && \
    sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.1/fpm/php.ini && \
    sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" /etc/php/7.1/fpm/php.ini

RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/;clear_env = no/clear_env = no/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.1/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.1/fpm/pool.d/www.conf

RUN sed -i -e "/pid\s*=\s*\/run/c\pid = /run/php7.1-fpm.pid" /etc/php/7.1/fpm/php-fpm.conf

# Remove default nginx configuration and replace it with ours
RUN rm -Rf /etc/nginx/conf.d/* && \
    rm -Rf /etc/nginx/sites-available/default
COPY .docker/nginx.default.conf /etc/nginx/sites-available/default

# Copy the supervisor daemon config
COPY .docker/supervisord.conf /etc/supervisord.conf

# And the docker entrypoint
COPY .docker/docker.entrypoint.sh /
RUN chmod +x /docker.entrypoint.sh

# Cleanup the default 'website' and set the workdir and user to be the www-data home folder
WORKDIR /web
RUN chown -R www-data:www-data .

# Copy over the users SSH keys so they can use composer with the agency bitbucket account.
COPY .ssh /root/.ssh
RUN chmod 700 /root/.ssh && \
    chmod 644 /root/.ssh/id_rsa.pub && \
    chmod 600 /root/.ssh/id_rsa

# Finish by setting what the container will expose and the init script when the container starts
EXPOSE 80 443 6379
VOLUME [ "/web" ]
ENTRYPOINT ["/bin/bash", "/docker.entrypoint.sh"]

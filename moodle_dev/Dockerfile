# syntax=docker/dockerfile:1
FROM ubuntu:22.04
MAINTAINER mattp pozze30@gmail.com

# Initial setup requirements
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y graphviz git software-properties-common

# Sort Timezone
ENV TZ=Australia/Melebourne
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends tzdata

RUN apt install -y nginx
COPY assets/default /etc/nginx/sites-enabled/default
COPY assets/nginx.conf /etc/nginx/nginx.conf
#https://stackoverflow.com/questions/30822695/how-to-get-php-to-be-able-to-read-system-environment-variables

RUN mkdir /run/php
RUN mkdir /var/www/moodledata
RUN mkdir /var/www/phpunitdata
RUN mkdir /var/www/behatdata
RUN mkdir /var/www/behatfaildumps
RUN chown www-data:www-data -R /var/www/

# PHP setup
RUN add-apt-repository --yes ppa:ondrej/php
RUN apt-get -y update
RUN apt install -y php8.0 php8.0-cli php8.0-dev

RUN apt-get install -y graphviz php8.0-pgsql php8.0-common php8.0-zip php8.0-gd \
     php8.0-mbstring php8.0-curl php8.0-xml php8.0-bcmath php8.0-fpm php8.0-igbinary
RUN apt-get remove --purge -y apache2
RUN echo "exit 0" > /usr/sbin/policy-rc.d

# Setup profiling requirements.
RUN git clone https://github.com/tideways/php-xhprof-extension.git /tmp/tideways
WORKDIR /tmp/tideways
RUN phpize
RUN ./configure
RUN make
RUN make install

WORKDIR /var/www/html
RUN rm -rf /tmp/tideways

COPY assets/tideways.ini /usr/local/etc/php/conf.d/tideways.ini

# Setup debug requirements.
RUN pecl install xdebug
COPY assets/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
EXPOSE 80

STOPSIGNAL SIGQUIT

CMD /etc/init.d/php8.0-fpm restart && nginx -g "daemon off;"

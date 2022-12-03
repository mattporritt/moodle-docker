# syntax=docker/dockerfile:1
FROM arm64v8/ubuntu:22.04
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

# PHP setup
RUN add-apt-repository --yes ppa:ondrej/php
RUN apt-get -y update
RUN apt install -y php7.4 php7.4-cli php7.4-dev

RUN apt-get install -y graphviz php7.4-pgsql php7.4-json php7.4-common php7.4-zip php7.4-gd \
     php7.4-mbstring php7.4-curl php7.4-xml php7.4-bcmath php7.4-fpm
RUN apt-get remove --purge -y apache2

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

CMD ["nginx", "-g", "daemon off;"]

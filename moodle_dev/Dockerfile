# syntax=docker/dockerfile:1
FROM moodlehq/moodle-php-apache:7.4
MAINTAINER mattp pozze30@gmail.com

# Setup profiling requirements.
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y graphviz

RUN git clone https://github.com/tideways/php-xhprof-extension.git /tmp/tideways
WORKDIR /tmp/tideways
RUN phpize  \
RUN ./configure \
RUN make \
RUN make install

WORKDIR /var/www/html
RUN rm -rf /tmp/tideways

COPY assets/tideways.ini /usr/local/etc/php/conf.d/tideways.ini

# Setup debug requirements.
RUN pecl install xdebug
COPY assets/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

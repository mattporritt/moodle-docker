# syntax=docker/dockerfile:1
FROM moodlehq/moodle-php-apache:8.0
MAINTAINER stevando stevando.sm@gmail.com

# Setup profiling requirements.
RUN apt-get -y update
RUN ACCEPT_EULA=Y apt-get upgrade -y
RUN apt-get install -y graphviz

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

# SSL for Apache2
COPY assets/certs/ /etc/ssl/certs/
COPY assets/443-default.conf /etc/apache2/sites-enabled/443-default.conf
RUN a2enmod ssl

COPY assets/certs/ /usr/local/share/ca-certificates/
RUN update-ca-certificates

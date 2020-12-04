FROM alpine:3.12

# RUN echo $'\n@edge http://dl-cdn.alpinelinux.org/alpine/edge/main\n\
# @edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories

RUN apk --update \
    add apache2 \
    bash \
    curl \
    php7-apache2 \
    php7-bcmath \
    php7-bz2 \
    php7-calendar \
    php7-common \
    php7-ctype \
    php7-curl \
    php7-dom \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-mcrypt \
    php7-mysqli \
    php7-mysqlnd \
    php7-openssl \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-pdo_sqlite \
    php7-phar \
    php7-session \
    php7-xml \
    php7-xmlreader \
    php7-zip \
    php7-simplexml \
    php7-intl \
    php7-fileinfo \
    php7-xmlrpc \
    php7-pecl-xdebug \
    mysql-client \
    && rm -f /var/cache/apk/* \
    && mkdir -p /opt/scripts \
    && mkdir /moodle

EXPOSE 80

ADD ./rootfs /

RUN chmod +X /opt/scripts/image-setup.sh
RUN /opt/scripts/image-setup.sh

ENTRYPOINT ["/opt/scripts/entrypoint.sh"]



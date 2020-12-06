#!/bin/sh

# Create users for php-fpm
addgroup www
adduser -S www -G www

# Change nginx config
sed -i 's@access_log.*@access_log /dev/stdout main;@g' /etc/nginx/nginx.conf
sed -i 's@error_log.*@error_log /dev/stdout warn;@g' /etc/nginx/nginx.conf
echo 'pid /run/nginx.pid;' >> /etc/nginx/nginx.conf
echo 'daemon off;' >> /etc/nginx/nginx.conf

# Add server conf to nginx
rm /etc/nginx/conf.d/default.conf
cat > /etc/nginx/conf.d/moodle.conf <<EOF
server {
    listen 80 default_server;
    root /moodle;
    index index.php index.html index.htm;
    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info  ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi.conf;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

# Change php-fpm configuration
sed -i 's@^user.*@user = www@g' /etc/php7/php-fpm.d/www.conf
sed -i 's@^group.*@group = www@g' /etc/php7/php-fpm.d/www.conf
sed -i 's@^;chdir=.*@chdir = /moodle@g' /etc/php7/php-fpm.d/www.conf

# Modify php.ini settings
sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php7/php.ini
sed -i "s/^;date.timezone =$/date.timezone = \"Asia\/Kolkata\"/" /etc/php7/php.ini

# Enable xdebug
sed -ri 's#^;(zend.*)$#zend_extension=xdebug#g' /etc/php7/conf.d/xdebug.ini
echo "xdebug.remote_enable=1" >> /etc/php7/conf.d/xdebug.ini
echo "xdebug.remote_host=host.docker.internal" >> /etc/php7/conf.d/xdebug.ini

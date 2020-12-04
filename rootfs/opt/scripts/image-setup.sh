#!/bin/sh

# Change apache config
sed -i 's/#ServerAdmin\ you@example.com/ServerAdmin\ you@example.com/' /etc/apache2/httpd.conf
sed -i 's/#ServerName\ www.example.com:80/ServerName\ www.example.com:80/' /etc/apache2/httpd.conf
sed -i 's#^DocumentRoot ".*#DocumentRoot "/moodle"#g' /etc/apache2/httpd.conf
sed -i 's#Directory "/var/www/localhost/htdocs"#Directory "/moodle"#g' /etc/apache2/httpd.conf
sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf

# apache logging
sed -ri 's@^ErrorLog.*$@ErrorLog /dev/stdout@g' /etc/apache2/httpd.conf
sed -ri 's@CustomLog logs/access.log combined@CustomLog /dev/stdout combined@g' /etc/apache2/httpd.conf

# Enable commonly used apache modules
sed -i 's/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/' /etc/apache2/httpd.conf
sed -i 's/#LoadModule\ deflate_module/LoadModule\ deflate_module/' /etc/apache2/httpd.conf
sed -i 's/#LoadModule\ expires_module/LoadModule\ expires_module/' /etc/apache2/httpd.conf

# Modify php.ini settings
sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php7/php.ini
sed -i "s/^;date.timezone =$/date.timezone = \"Asia\/Kolkata\"/" /etc/php7/php.ini

# Enable xdebug
sed -ri 's#^;(zend.*)$#zend_extension=xdebug#g' /etc/php7/conf.d/xdebug.ini
echo "xdebug.remote_enable=1" >> /etc/php7/conf.d/xdebug.ini
echo "xdebug.remote_host=host.docker.internal" >> /etc/php7/conf.d/xdebug.ini

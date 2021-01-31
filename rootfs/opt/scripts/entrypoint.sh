#! /bin/bash

set -e

# Wait for Mariadb to comeup
max_retries=3
i=1
mariadb_connection_args=("-h" "$MOODLE_DB_HOST" "-u" "$MOODLE_DB_USER")
if [ ! -z "$MOODLE_DB_PASSWORD" ]; then
    args+=("-p=$MOODLE_DB_PASSWORD")
fi

echo "Attempting to connect to MariaDB"
until mysqladmin "${mariadb_connection_args[@]}" "status"
do
    sleep 5 && [[ i -eq $max_retries ]] && echo "MariaDB didn't comeup on time" && exit 1
    echo "Attempting to connect to MariaDB (#$i)"
    ((i++))
done

if [ -a /moodle/.initialized ]; then
    echo "Initialized"
else
    # initialize moodle
    if [ ! -d /moodledata ]; then
        echo "The directory '/moodledata' does not exist. Mount a Docker volume or a host directory to this folder."
        exit 127
    fi

    chown root:root /moodle /moodledata

    # Create database if it does not exist
    mysqlshow "${mariadb_connection_args[@]}" "$MOODLE_DB_NAME" > /dev/null 2>&1 || mysqladmin "${mariadb_connection_args[@]}" create "$MOODLE_DB_NAME"

    if [ ! -f /moodle/config.php ]; then
        # install moodle
        cmdopts=(
            "--non-interactive"
            "--chmod=2750"
            "--wwwroot=http://localhost:80"
            "--dataroot=/moodledata"
            "--dbtype=mariadb"
            "--fullname=Moodle Dev"
            "--shortname=Moodle Dev"
            "--dbhost=$MOODLE_DB_HOST"
            "--dbname=$MOODLE_DB_NAME"
            "--dbuser=$MOODLE_DB_USER"
            "--dbpass=$MOODLE_DB_PASSWORD"
            "--dbport=$MOODLE_DB_PORT"
            "--adminemail=admin@email.com"
            "--adminpass=adminadmin"
            "--agree-license"
        )

        if [ ! -z "$MOODLE_SKIP_DATABASE_INSTALL" ]; then
            cmdopts+=("--skip-database")
        fi

        # Install Moodle
        php /moodle/admin/cli/install.php "${cmdopts[@]}"

        # Change wwwroot so that instance is accessible from any ip
        delimiter=$'\001'
        new_root="// Configure wwwroot to be accessible from any ip\\
if (empty(\$_SERVER['HTTP_HOST'])) {\\
    \$_SERVER['HTTP_HOST'] = 'localhost:80';\\
}\\
if (isset(\$_SERVER['HTTPS']) \&\& \$_SERVER['HTTPS'] == 'on') {\\
  \$CFG->wwwroot   = 'https://' . \$_SERVER['HTTP_HOST'];\\
} else {\\
  \$CFG->wwwroot   = 'http://' . \$_SERVER['HTTP_HOST'];\\
}"
        sed -Ei "s${delimiter}\\\$CFG->wwwroot\s*=(.*)${delimiter}${new_root}${delimiter}g" /moodle/config.php


        # Add Debug info
        cat >> /moodle/config.php <<EOF
@error_reporting(E_ALL | E_STRICT);
@ini_set('display_errors', '1');
\$CFG->debug = (E_ALL | E_STRICT);
\$CFG->debugdisplay = 1;
EOF
    else
        # Install database

        cmdopts=(
            "--dataroot=/moodledata"
            "--dbtype=mariadb"
            "--fullname=Moodle Dev"
            "--shortname=Moodle Dev"
            "--adminemail=admin@email.com"
            "--adminpass=adminadmin"
            "--agree-license"
        )

        php /moodle/admin/cli/install_database.php "${cmdopts[@]}"
    fi

    touch /moodle/.initialized
fi

# Install composer packages
composer install -d /moodle

# Dump current environment
declare -px > /env.sh

# Start crond in the background
/usr/sbin/crond

# Upgrade Moodle
php /moodle/admin/cli/upgrade.php --non-interactive

# Change file system permissions
chmod -R 777 /moodle /moodledata

# Start php-fpm and nginx
/usr/sbin/php-fpm7
exec /usr/sbin/nginx


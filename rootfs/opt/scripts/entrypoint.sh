#! /bin/bash

set -e

# Wait for Mariadb to comeup
max_retries=3
i=1
args=("-h" "$MOODLE_DB_HOST" "-u" "$MOODLE_DB_USER" "status")
if [ ! -z "$MOODLE_DB_PASSWORD" ]; then
    args+=("-p=$MOODLE_DB_PASSWORD")
fi

echo "Attempting to connect to MariaDB"
until mysqladmin "${args[@]}"
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

    pushd /moodle/admin/cli > /dev/null
    php install.php "${cmdopts[@]}"
    popd > /dev/null

    # Add Debug info
    cat >> /moodle/config.php <<EOF
@error_reporting(E_ALL | E_STRICT);
@ini_set('display_errors', '1');
\$CFG->debug = (E_ALL | E_STRICT);
\$CFG->debugdisplay = 1;
EOF
    touch /moodle/.initialized
fi

# Setup host route
netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2" host.docker.internal"}' >> /etc/hosts

# Dump current environment
declare -px > /env.sh

# Start crond in the background
/usr/sbin/crond

# Upgrade Moodle
php /moodle/admin/cli/upgrade.php --non-interactive
exec /usr/sbin/httpd -D "FOREGROUND"

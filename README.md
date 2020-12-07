# Docker environment for Moodle development
This Docker image provides a development environment for Moodle. It isn't by any means meant for a production environment.

The image is based off of Alpine and runs Nginx+PHP-FPM. [bitnami/mariadb](https://hub.docker.com/r/bitnami/mariadb) is used to setup the MariaDB database. XDebug 2.9.8 is also installed.

## Environment variables
The following environment variables are used by this image:

* `MOODLE_DB_HOST`: The hostname of the MariaDB instance.
* `MOODLE_DB_PORT`: The port of the MariaDB instance.
* `MOODLE_DB_NAME`: The name of the database.
* `MOODLE_DB_USER`: A valid username for the database instance.
* `MOODLE_DB_PASSWORD`: A valid password for the database instance. Can be left blank.
* `MOODLE_SKIP_DATABASE_INSTALL`: Set to a non-empty string to skip the database boostrapping process. Useful if you already have a database and simply require Moodle to install a `config.php` file.

In addition to these, you can also set environment variables used by other applications, particular XDebug.

## Docker Volumes
The image expects you to supply the Moodle source code in the form of a bind mount. The Moodle source code should be mounted to `/mount` inside the container.

The 'moodledata' folder should be mounted to '/moodledata'. This can either be a volume or a bind mount. The included Compose configuration binds mounts the './moodledata'. This is so that you can inspect files inside the directory if need be. A volume mount works as well.

## Using
Clone this repository and (assuming you have Docker and Docker Compose) run the following command (after creating a `docker-compose.yml` file) from the root of the repo: `docker-compose build`.

You can then run `docker-compose up` to bring the database and web application up.

After first install of Moodle, the file '.initialized' is placed inside '/moodle' folder, which should be bind mounted. Subsequent container creation/starts will not result in a reinstall. In case a reinstall is required without reinitializing the database, the '.initialized' file can be removed and the `MOODLE_SKIP_DATABASE_INSTALL` environment variable can be set to a non-emptry string.

If the container starts up sucessfully, the Moodle instance can be visited on 'http://localhost' on the host machine.

This image uses the `php7-pecl-xdebug` package from Alpine's package repository. As of writing this document, XDebug 2.9.8 is the default with 3.0 in the edge branch.


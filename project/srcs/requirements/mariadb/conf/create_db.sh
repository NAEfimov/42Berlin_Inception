#!/bin/sh

DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
    echo "Critical Error: Variables DB_NAME and DB_USER not in the container!"
    exit 1
fi

chown -R mysql:mysql /var/lib/mysql

# If there is no system DB
if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "System tables initialisation MariaDB..."
        mysql_install_db --basedir=/usr --datadir=/var/lib/mysql --user=mysql --rpm
fi

# If there is no user DB
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
        echo "Creatind database and users..."

        tfile=$(mktemp)
        if [ ! -f "$tfile" ]; then
                exit 1
        fi

        cat << EOF > "$tfile"

USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

        # Structure initialisation in bootstrap mode
        /usr/bin/mariadbd --user=mysql --bootstrap < "$tfile"
        rm -f "$tfile"
fi

echo "Running MariaDB..."
# Run main process
exec /usr/bin/mariadbd --user=mysql --skip-log-error

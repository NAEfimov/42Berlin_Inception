#!/bin/sh
set -e

# Read password from Docker Secret
if [ -f "/run/secrets/db_password" ]; then
    DB_PASSWORD="$(cat /run/secrets/db_password)"
fi

if [ -z "${DB_NAME}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASSWORD}" ]; then
    echo "Error: DB_NAME, DB_USER, or DB_PASSWORD is not set!"
    exit 1
fi

# Read WordPress installation secrets
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user 2>/dev/null || echo "")
WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password 2>/dev/null || echo "")
WP_USER=$(cat /run/secrets/wp_user 2>/dev/null || echo "")
WP_USER_PASS=$(cat /run/secrets/wp_user_password 2>/dev/null || echo "")

# Set fallbacks if environment variables are empty
WP_ADMIN_URL=${WP_ADMIN_URL:-"https://nefimov.42.fr"}
WP_ADMIN_TITLE=${WP_ADMIN_TITLE:-"My Inception Site"}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-"admin@example.com"}

WP_USER_EMAIL=${WP_USER_EMAIL:-"user@example.com"}
WP_USER_ROLE=${WP_USER_ROLE:-"subscriber"}


# Validate Administrator username requirements
LOW_ADMIN_USER=$(echo "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')
if [ -z "$WP_ADMIN_USER" ]; then
    echo "Error: wp_admin_user secret is empty!"
    exit 1
fi

if echo "$LOW_ADMIN_USER" | grep -E "admin|administrator" > /dev/null; then
    echo "Error: Administrator username cannot contain 'admin' or 'administrator'!"
    exit 1
fi

# Create wp-config.php if it doesn't exist
if [ ! -f "/var/www/wp-config.php" ]; then
    echo "Creating wp-config.php configuration file..."

    # Generate random salt text
    generate_salt() {
        tr -dc 'a-zA-Z0-9!@#%^&*()-_=+[]{}|;:,.<>?' < /dev/urandom | head -c 64
    }

    # Open the PHP tag in the configuration file
    cat << 'EOF' > /var/www/wp-config.php
<?php
if ( defined( 'WP_CLI' ) && WP_CLI && ! isset( $_SERVER['HTTP_HOST'] ) ) {
    $_SERVER['HTTP_HOST'] = 'localhost';
}
EOF

    # Safely inject runtime environment variables into the PHP config
    {
        echo "define( 'DB_NAME', '${DB_NAME}' );"
        echo "define( 'DB_USER', '${DB_USER}' );"
        echo "define( 'DB_PASSWORD', '${DB_PASSWORD}' );"
    } >> /var/www/wp-config.php

	# Inject generated salts
    {
        echo "define( 'AUTH_KEY',         '$(generate_salt)' );"
        echo "define( 'SECURE_AUTH_KEY',  '$(generate_salt)' );"
        echo "define( 'LOGGED_IN_KEY',    '$(generate_salt)' );"
        echo "define( 'NONCE_KEY',        '$(generate_salt)' );"
        echo "define( 'AUTH_SALT',        '$(generate_salt)' );"
        echo "define( 'SECURE_AUTH_SALT', '$(generate_salt)' );"
        echo "define( 'LOGGED_IN_SALT',   '$(generate_salt)' );"
        echo "define( 'NONCE_SALT',       '$(generate_salt)' );"
    } >> /var/www/wp-config.php

    # Append the static WordPress configuration blocks
    cat << 'EOF' >> /var/www/wp-config.php
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define( 'FS_METHOD', 'direct' );

$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_TIMEOUT', 1 );
define( 'WP_REDIS_READ_TIMEOUT', 1 );
define( 'WP_REDIS_DATABASE', 0 );

require_once ABSPATH . 'wp-settings.php';
EOF
    echo "wp-config.php file has been successfully created."
fi

# Handle automated WordPress installation via WP-CLI

cd /var/www

if [ ! -f "/usr/local/bin/wp" ]; then
    echo "Downloading WP-CLI..."
    curl -O https://githubusercontent.com
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

chown -R nobody:nobody /var/www

# Waiting for MariaDB to start
echo "Waiting for MariaDB to start..."
until nc -z -v -w3 mariadb 3306; do
    echo "MariaDB is unavailable - sleeping..."
    sleep 2
done
echo "MariaDB is up and running! Proceeding with WordPress setup..."

set +e

# Check if WordPress is already installed in the database
if ! su -s /bin/sh nobody -c "wp core is-installed"; then
    echo "WordPress is not installed. Initializing database tables..."

    # Install WordPress and create the custom Administrator
    su -s /bin/sh nobody -c "wp core install \
        --url='${WP_ADMIN_URL}' \
        --title='${WP_ADMIN_TITLE}' \
        --admin_user='${WP_ADMIN_USER}' \
        --admin_password='${WP_ADMIN_PASS}' \
        --admin_email='${WP_ADMIN_EMAIL}' \
        --skip-email"

	# Check if the previous command succeeded
    if [ $? -eq 0 ]; then
        echo "Administrator created successfully."
    else
        echo "Error: Failed to install WordPress core!"
    fi

    # Create the second (regular) user if credentials are provided
    if [ -n "$WP_USER" ] && [ -n "$WP_USER_PASS" ]; then
        echo "Creating the second regular user: ${WP_USER}..."
        su -s /bin/sh nobody -c "wp user create \
            '${WP_USER}' \
            '${WP_USER_EMAIL}' \
            --user_pass='${WP_USER_PASS}' \
            --role='${WP_USER_ROLE}'"

		if [ $? -eq 0 ]; then
            echo "Second user created successfully!"
        else
            echo "Error: Failed to create the second user. Check if credentials are valid."
        fi

    else
		echo "Warning: WP_USER or WP_USER_PASS secret is empty. Skipping second user creation."
	fi
    echo "WordPress installation and user creation completed successfully!"
else
    echo "WordPress database is already initialized."
fi

set -e

# Locate and execute PHP-FPM
chown -R nobody:nobody /var/www/wp-content

PHP_FPM_BIN=$(find /usr/sbin -name "php-fpm*" | head -n 1)

if [ -z "$PHP_FPM_BIN" ]; then
    echo "Error: php-fpm binary could not be found in /usr/sbin!"
    exit 1
fi

echo "Starting $PHP_FPM_BIN..."

exec $PHP_FPM_BIN -F

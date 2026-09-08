!/bin/bash

mkdir project
cd project

touch Makefile

mkdir secrets
touch secrets/credentials.txt
touch secrets/db_password.txt
touch secrets/db_root_password.txt

mkdir srcs
touch srcs/docker-compose.yml
touch srcs/.env
mkdir srcs/requirements

mkdir srcs/requirements/bonus
mkdir srcs/requirements/mariadb
mkdir srcs/requirements/mariadb/conf
touch srcs/requirements/mariadb/conf/create_db.sh
mkdir srcs/requirements/mariadb/tools

echo "" > srcs/requirements/mariadb/tools/.gitkeep
touch srcs/requirements/mariadb/Dockerfile
touch srcs/requirements/mariadb/.dockerignore
echo ".git" > srcs/requirements/mariadb/.dockerignore
echo ".env" >> srcs/requirements/mariadb/.dockerignore

mkdir srcs/requirements/nginx
mkdir srcs/requirements/nginx/conf
touch srcs/requirements/nginx/conf/nginx.conf
mkdir srcs/requirements/nginx/tools
touch srcs/requirements/nginx/Dockerfile
echo ".git" > srcs/requirements/nginx/.dockerignore
echo ".env" >> srcs/requirements/nginx/.dockerignore
mkdir srcs/requirements/tools
mkdir srcs/requirements/wordpress
mkdir srcs/requirements/wordpress/conf
touch srcs/requirements/wordpress/conf/wp-config-create.sh
mkdir srcs/requirements/wordpress/tools
echo "" > srcs/requirements/wordpress/tools/.gitkeep
touch srcs/requirements/wordpress/Dockerfile
echo ".git" > srcs/requirements/wordpress/.dockerignore
echo ".env" >> srcs/requirements/wordpress/.dockerignore

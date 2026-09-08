FROM alpine:3.24

ARG DB_NAME \
	DB_USER

RUN apk update && apk upgrade && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /var/run/mysqld /var/lib/mysql && \
	chown -R mysql:mysql /var/run/mysqld /var/lib/mysql && \
	chmod 777 /var/run/mysqld

RUN	{ echo '[mysqld]'; \
      echo 'skip-host-cache'; \
      echo 'skip-name-resolve'; \
      echo 'bind-address=0.0.0.0'; \
    } | tee  /etc/my.cnf.d/docker.cnf; \
    sed -i "s|skip-networking|skip-networking=0|g" \
      /etc/my.cnf.d/mariadb-server.cnf

EXPOSE 3306

COPY requirements/mariadb/conf/create_db.sh /usr/local/bin/create_db.sh
RUN chmod +x /usr/local/bin/create_db.sh

ENTRYPOINT ["/usr/local/bin/create_db.sh"]

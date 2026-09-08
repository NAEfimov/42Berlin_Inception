FROM alpine:3.24

ARG PHP_VERSION \
	DB_NAME \
	DB_USER	

RUN apk update && apk upgrade && apk add --no-cache \
	php${PHP_VERSION} \
	php${PHP_VERSION}-fpm \
	php${PHP_VERSION}-mysqli \
	php${PHP_VERSION}-json \
	php${PHP_VERSION}-mysqlnd \
	php${PHP_VERSION}-curl \
	php${PHP_VERSION}-dom \
	php${PHP_VERSION}-exif \
	php${PHP_VERSION}-fileinfo \
	php${PHP_VERSION}-gd \
	php${PHP_VERSION}-intl \
	php${PHP_VERSION}-mbstring \
	php${PHP_VERSION}-openssl \
	php${PHP_VERSION}-xml \
	php${PHP_VERSION}-zip \
	php${PHP_VERSION}-phar \
	php${PHP_VERSION}-redis \
	wget \
	unzip \
	curl \
	less

RUN ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php && \
    ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm

#RUN curl -o /usr/local/bin/wp https://githubusercontent.com \
#    && chmod +x /usr/local/bin/wp
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

RUN sed -i -e "s|listen = 127.0.0.1:9000|listen = 9000|g" \
           -e "s|;listen.owner = nobody|listen.owner = nobody|g" \
           -e "s|;listen.group = nobody|listen.group = nobody|g" \
           /etc/php${PHP_VERSION}/php-fpm.d/www.conf && \
    rm -f /var/cache/apk/*

WORKDIR /var/www

RUN wget https://wordpress.org/latest.zip && \
    unzip latest.zip && \
    cp -rf wordpress/* . && \
    rm -rf wordpress latest.zip

COPY ./requirements/wordpress/tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]

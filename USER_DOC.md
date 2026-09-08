# User Documentation

## Services

The Inception stack provides three services:

- **Nginx** receives HTTPS requests on port `443` and serves the website.
- **WordPress** runs the WordPress application through PHP-FPM. Its PHP-FPM port is private to the Docker network.
- **MariaDB** stores the WordPress database. It is available to the other containers through the Docker network and is published on host port `3306`.

The normal request flow is:

```text
Browser -> Nginx -> WordPress/PHP-FPM -> MariaDB
```

## Starting the Project

Open a terminal in the `project/` directory and run:

```bash
make
```

To build the images before starting the services, run:

```bash
make build
```

The first startup may take time while the images are built, MariaDB is initialized, and WordPress creates its database tables.

## Stopping the Project

To stop and remove the running containers while keeping persistent data, run:

```bash
make down
```

To stop the project and remove containers, images, volumes, and stored WordPress and MariaDB data, run:

```bash
make fclean
```

`make fclean` is destructive and requires `sudo`. It deletes the website and database data stored under `~/data`.

## Accessing the Website

The Nginx configuration uses the hostnames `nefimov.42.fr` and `www.nefimov.42.fr`. Make sure the hostname resolves to the Docker host. For local testing, add an appropriate entry to `/etc/hosts`, for example:

```text
127.0.0.1 nefimov.42.fr www.nefimov.42.fr
```

Then open:

```text
https://nefimov.42.fr/
```

Because the project uses a locally generated or self-signed certificate, the browser may display a certificate warning during local testing.

## Accessing the Administration Panel

Open the WordPress administration panel at:

```text
https://nefimov.42.fr/wp-admin/
```

Use the administrator username and password stored in:

```text
/home/nefimov/project/secrets/wp_admin_user.txt
/home/nefimov/project/secrets/wp_admin_password.txt
```

The WordPress entrypoint creates the administrator during the first successful installation. If WordPress is already installed, changing the secret files does not automatically change the existing WordPress password.

## Credentials and Certificates

Sensitive values are provided to containers through Docker secrets. The current Compose configuration expects these files under `/home/nefimov/project/secrets/`:

- `db_password.txt`: password for the WordPress database user.
- `db_root_password.txt`: MariaDB root password.
- `wp_admin_user.txt`: WordPress administrator username.
- `wp_admin_password.txt`: WordPress administrator password.
- `wp_user.txt`: regular WordPress username.
- `wp_user_password.txt`: regular WordPress password.
- `nefimov.42.fr.crt`: TLS certificate.
- `nefimov.42.fr.key`: TLS private key.

Keep these files private and never commit them to Git. If the repository is installed in another location, update the absolute secret paths in `project/srcs/docker-compose.yml`.

## Checking the Services

From the `project/` directory, list the containers:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

The `nginx`, `wordpress`, and `mariadb` services should be running. To inspect recent logs, use:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=50 nginx
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=50 wordpress
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs --tail=50 mariadb
```

Check the HTTPS endpoint with:

```bash
curl -kI https://nefimov.42.fr/
```

A response from Nginx confirms that the HTTPS service is reachable. If WordPress is still initializing, wait a few seconds and check the WordPress and MariaDB logs again.

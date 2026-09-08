# Developer Documentation

## Project Layout

The implementation is under `project/`:

- `Makefile`: build, run, stop, and cleanup commands.
- `srcs/docker-compose.yml`: Compose services, networks, volumes, and secrets.
- `srcs/requirements/nginx/`: Nginx Dockerfile and HTTPS configuration.
- `srcs/requirements/wordpress/`: WordPress Dockerfile and startup entrypoint.
- `srcs/requirements/mariadb/`: MariaDB Dockerfile and database initialization script.
- `srcs/.env.example`: template for non-sensitive environment configuration.

## Prerequisites

Install the following on the host:

- Docker Engine.
- Docker Compose plugin, providing `docker compose`.
- GNU Make.
- OpenSSL for creating or inspecting TLS certificates.

The project was developed on Debian. Run project commands from the `project/` directory.

## Host Setup

The reference environment runs Debian without a graphical desktop inside VirtualBox. Download the Debian installation image from [debian.org](https://www.debian.org/) and create a regular development user, such as `nefimov`, in addition to `root`.

### Install Docker on Debian

As `root`, add Docker's official repository and key:

```bash
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify the installation:

```bash
docker run hello-world
```

Install the remaining host tools:

```bash
apt install -y sudo ufw make openbox xinit kitty firefox-esr
```

Add the development user to the Docker group so Docker commands can run without `sudo`:

```bash
sudo usermod -aG docker nefimov
groups nefimov
```

Log out and back in, or start a new session, before using the updated group membership.

### SSH, Firewall, and VirtualBox Forwarding

For the reference VM, configure `/etc/ssh/sshd_config` with SSH port `4242`, then restart the SSH service:

```bash
service ssh restart
```

The original setup also enabled root and password authentication for local VM access. These settings are convenient for a disposable development VM but should not be exposed on an untrusted network; prefer a regular user with SSH keys for normal use.

Allow the required host ports through UFW:

```bash
ufw allow 4242
ufw allow 80
ufw allow 443
ufw status
```

In VirtualBox, open `Settings -> Network -> Port Forwarding` and add:

| Rule | Host port | Guest port |
| --- | ---: | ---: |
| HTTP | `8080` | `80` |
| HTTPS | `8443` | `443` |
| SSH | `4242` | `4242` |

Connect to the VM with:

```bash
ssh nefimov@localhost -p 4242
```

The current Compose configuration publishes HTTPS on port `443`. The VirtualBox HTTP rule is retained because it is part of the reference host setup, although the current Nginx configuration does not listen on port `80`.

## Configuration From Scratch

Create the environment file from the committed template:

```bash
cd project
cp srcs/.env.example srcs/.env
```

Set the values required by the Compose file and WordPress entrypoint:

- `DB_NAME`: WordPress database name.
- `DB_USER`: database user name.
- `DB_HOST`: database host setting.
- `PHP_VERSION`: PHP package version available in Alpine.
- `WP_ADMIN_URL`: public WordPress URL.
- `WP_ADMIN_TITLE`: site title.
- `WP_ADMIN_EMAIL`: administrator email.
- `WP_USER_EMAIL`: regular user email.
- `WP_USER_ROLE`: regular user role.

Do not put passwords in `.env`. The Compose file reads sensitive values from Docker secret files. Before starting the project, create:

```text
/home/nefimov/project/secrets/nefimov.42.fr.crt
/home/nefimov/project/secrets/nefimov.42.fr.key
/home/nefimov/project/secrets/db_password.txt
/home/nefimov/project/secrets/db_root_password.txt
/home/nefimov/project/secrets/wp_admin_user.txt
/home/nefimov/project/secrets/wp_admin_password.txt
/home/nefimov/project/secrets/wp_user.txt
/home/nefimov/project/secrets/wp_user_password.txt
```

The certificate must match the hostnames configured in `srcs/requirements/nginx/conf/nginx.conf`. The paths are absolute in the current Compose file. If the repository is moved, update the secret paths or provide the expected directory.

## Build and Launch

The Makefile creates the host data directories and starts the stack:

```bash
make
```

Build custom images and start the services:

```bash
make build
```

The direct Docker Compose equivalent is:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build
```

The three services are connected to the user-defined `inception` bridge network. Nginx publishes port `443`, MariaDB publishes port `3306`, and WordPress PHP-FPM listens only inside the Docker network on port `9000`.

## Container and Volume Management

List service status:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
```

Follow all service logs:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs -f
```

Follow one service:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env logs -f wordpress
```

Stop and remove containers without removing persistent data:

```bash
make down
```

Rebuild and relaunch the services:

```bash
make re
```

Remove the local project images:

```bash
make clean
```

Remove containers, volumes, images, and stored application data:

```bash
make fclean
```

Inspect the Docker volumes:

```bash
docker volume ls
docker volume inspect wp_volume db_volume
```

The Compose volume names are `wp_volume` and `db_volume`.

## Data Storage and Persistence

The Makefile creates these host directories:

```text
~/data/wordpress
~/data/mariadb
```

The Compose file declares named volumes but configures them with bind-driver options pointing to those host directories. WordPress files persist in `~/data/wordpress`, and MariaDB data persists in `~/data/mariadb` when containers are recreated.

`make down`, `make re`, and `make clean` preserve the host data. `make fclean` removes the contents of both directories and should only be used when a complete reset is intended.

## Initialization Behavior

MariaDB initializes its system tables, creates the configured database and user, and then starts the database server. WordPress reads its credentials from `/run/secrets`, creates `wp-config.php` if needed, waits until MariaDB accepts connections, and uses WP-CLI to install WordPress and create users on the first run. Nginx serves the shared WordPress files and forwards PHP requests to `wordpress:9000`.

When diagnosing startup issues, check MariaDB first, then WordPress initialization, and finally Nginx logs. The current Compose file does not define a Redis service, even though the generated WordPress configuration contains Redis-related constants.

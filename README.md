*This project has been created as part of the 42 curriculum by nefimov.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. Its goal is to build a WordPress hosting stack with Docker Compose and understand how services, networks, persistent storage, TLS, and credentials work together.

The project contains three custom Alpine Linux containers:

- **Nginx**: public HTTPS entry point, TLS termination, and reverse proxy.
- **WordPress**: WordPress with PHP-FPM and WP-CLI. It creates `wp-config.php`, waits for MariaDB, and installs WordPress on first start.
- **MariaDB**: database server with an initialization script that creates the application database and user.

The request path is `client -> Nginx:443 -> WordPress:9000 -> MariaDB:3306`. WordPress and MariaDB communicate through the private `inception` Docker bridge network. Nginx publishes HTTPS on host port `443`; MariaDB is also published on host port `3306`.

### Project Structure

- `project/Makefile`: commands for building, starting, stopping, and cleaning the stack.
- `project/srcs/docker-compose.yml`: service, network, volume, and secret definitions.
- `project/srcs/requirements/nginx/`: Nginx image and HTTPS configuration.
- `project/srcs/requirements/wordpress/`: PHP-FPM, WordPress, WP-CLI, and initialization logic.
- `project/srcs/requirements/mariadb/`: MariaDB image and database initialization script.
- `project/srcs/.env.example`: template for non-sensitive configuration.

## Instructions

### Prerequisites

Install Docker Engine, the Docker Compose plugin, GNU Make, and OpenSSL on a Linux host. The original development environment uses Debian. Run the commands below from `project/`.

### Configuration

Create the environment file:

```bash
cd project
cp srcs/.env.example srcs/.env
```

Fill in `srcs/.env` with values for `DB_NAME`, `DB_USER`, `DB_HOST`, `PHP_VERSION`, and the WordPress site and user settings. Keep passwords out of this file.

Create the secret files consumed by Compose:

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

The current Compose file uses these absolute paths. If the repository is stored elsewhere, update the paths in `srcs/docker-compose.yml` or create the expected directory. Keep secrets out of version control and restrict their permissions.

Create a certificate matching `nefimov.42.fr` and `www.nefimov.42.fr`, and make the hostname resolve to the Docker host, for example:

```text
127.0.0.1 nefimov.42.fr www.nefimov.42.fr
```

### Run the Project

```bash
make
```

Open `https://nefimov.42.fr/` after the containers are ready. PHP-FPM port `9000` is internal to Docker.

Available Make targets:

| Target | Action |
| --- | --- |
| `make` or `make all` | Create host data directories and start the stack. |
| `make build` | Build images and start the stack. |
| `make down` | Stop and remove the services. |
| `make re` | Stop, rebuild, and start the stack. |
| `make clean` | Stop the stack and remove locally built images. |
| `make fclean` | Remove services, volumes, images, and stored WordPress/MariaDB data. |
| `make setup` | Create `~/data`, `~/data/wordpress`, and `~/data/mariadb`. |

Persistent data is stored in `~/data/wordpress` and `~/data/mariadb`. `make fclean` deletes this data and requires `sudo`.

## Technical Choices

### Docker and Included Sources

Each required service is built from its own Dockerfile rather than using a pre-built application image. The Dockerfiles use Alpine Linux and install only the packages needed by each service. The project supplies the Nginx configuration, MariaDB initialization script, and WordPress entrypoint. WordPress and WP-CLI are downloaded during the WordPress image build.

### Virtual Machines vs Docker

A virtual machine runs a complete guest operating system with its own kernel, requiring more memory, storage, and startup time. Docker containers share the host kernel while isolating processes, filesystems, and networks, so they are lighter and faster to rebuild. This project uses one container per service because the services need separate lifecycles but do not need separate operating systems.

### Secrets vs Environment Variables

Environment variables are used for non-sensitive settings such as database names, usernames, PHP version, and WordPress metadata. Passwords, WordPress credentials, and TLS private material are provided as Docker secrets and read from `/run/secrets`. Secret source files still require secure permissions and must not be committed.

### Docker Network vs Host Network

The user-defined `inception` bridge network provides isolated networking and Docker DNS service discovery. WordPress can reach MariaDB using the service name `mariadb`. Host networking removes this boundary and shares the host network namespace. The bridge network is appropriate here because only explicitly published ports need to be reachable from the host.

### Docker Volumes vs Bind Mounts

Docker-managed volumes let Docker choose and manage storage. Bind mounts map explicit host paths into containers and give administrators direct access to files. This project declares named volumes, `wp_volume` and `db_volume`, but configures them with the bind volume driver so data is stored at `~/data/wordpress` and `~/data/mariadb`.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker storage](https://docs.docker.com/engine/storage/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB documentation](https://mariadb.com/docs/)
- [WP-CLI documentation](https://wp-cli.org/)
- [WordPress documentation](https://wordpress.org/documentation/)

### AI Usage

GitHub Copilot was used as a supplementary resource to explain Docker, Docker Compose, networks, volumes, secrets, Nginx, MariaDB, WordPress, and configuration troubleshooting. It also helped draft and review documentation. Suggestions were checked against the project files and adapted by the author; the final architecture, configuration, and implementation decisions remain the author's responsibility.

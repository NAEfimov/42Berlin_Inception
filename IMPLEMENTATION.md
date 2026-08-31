### 1. Install Debian Linux in VirtualBox
Download Debian ISO image from web site `debian.org`
Install system with users `root` and `nefimov` without GUI

### 2. Install applications

### - Set up Docker's apt repository
Login as root user.

``` bash
# Add Docker's official GPG key:
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
```

### - Install the Docker packages
``` bash
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### - Verify that the installation is successful by running the hello-world image
``` bash
docker run hello-world
```
### - Install other applications

``` bash
apt install -y sudo ufw make openbox xinit kitty firefox-esr
```

### 3. First app settup

### - Add user to sudoers
Open file `nano /etc/sudoers` and add our user 'nefimov' after root.
Save file and close.

### - Add user to `docker` group
Run command
```
sudo usermod -aG docker nefimov
```

Check result by running command
```
groups nefimov
```

### 3. Port forwarding
### - SSH setup
Login as root and open file `/etc/ssh/sshd_config`

Set `Port 4242` and `PermitRootLogin yes`

Set `PubkeyAuthentication no` and `PasswordAuthentication yes`

Save changes and restart services `ssh` and `sshd`
``` bash
service ssh restart
service sshd restart
```

### - Firewall setup
Open port 4242 for SSH and ports 80 and 443 for HTTP and HTTPS
```bash
ufw allow 4242
ufw allow 80
ufw allow 443
```
Check ports with command
```bash
ufw status
```
### - VirtualBox port forwarding setup
In VirtualBox open `Settings -> Network -> Port Forwarding`
Add 3 new rules:
- http: 8080 <-> 80
- https: 8443 <-> 443
- ssh: 4242 <-> 4242

### Connect to the virtual machine by SSH
For root user:
``` bash
ssh root@localhost -p 4242
```
For regular user:
``` bash
ssh nefimov@localhost -p 4242
```

### 4. Create project structure

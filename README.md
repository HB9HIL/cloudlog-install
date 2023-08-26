# cloudlog Install Script

This Install Script is installing https://github.com/magicbug/Cloudlog on a Debian/Ubuntu System.

Supports English and German Language

### Usage

For detailed Information about this script you should check https://www.hb9hil.org/cloudlog-auf-einem-linux-server-installieren/ (german)


Install
```
sudo apt update && sudo apt install git -y && git clone https://github.com/HB9HIL/cloudlog-install.git && cd cloudlog-install && chmod +x cloudlog-install-v0.1.sh && bash cloudlog-install-v0.1.sh
```

Config Options

Use a editor of your choice to edit the script.
```
nano cloudlog-install-v0.1.sh
```

You can edit the following Variables if you have to:
```
DB_NAME=cloudlog
DB_USER=cloudloguser
DB_PASSWORD=$(openssl rand -base64 16)
INSTALL_PATH=/var/www/cloudlog
```

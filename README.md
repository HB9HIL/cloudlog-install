# cloudlog Install Script

This Install Script is installing https://github.com/magicbug/Cloudlog on a Debian/Ubuntu System.

It is successfully tested on
- Debian 11
- Debian 12
- Ubuntu 20.04
- Ubuntu 22.04

Supports English and German Language

### Usage

For detailed Information about this script you should check https://www.hb9hil.org/cloudlog-auf-einem-linux-server-installieren/ (german)

Install
```
sudo apt update && sudo apt install git -y && git clone https://github.com/HB9HIL/cloudlog-install.git && cd cloudlog-install && chmod +x cloudlog-install.sh && bash cloudlog-install.sh
```

Config Options

Use a editor of your choice to edit/view the script.
For example:
```
vi cloudlog-install.sh
```

You shouldn't edit any Variables in the Script! Everything important will be asked. If you miss something create an issue.


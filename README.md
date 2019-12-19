
Veles Masternode 1.0 Installer
==============================
![Licence](https://img.shields.io/github/license/velescore/masternode-installer?color=blue&style=for-the-badge)   ![Latest Release](https://img.shields.io/github/tag-pre/velescore/veles-installer.svg?style=for-the-badge) ![Master Build Status](https://img.shields.io/travis/velescore/masternode-installer/master?style=for-the-badge)

Official installer script for the last stable version of Veles Core Masternode 1st generation. This masternode version will be supported until Q2 2020, then they'll be replaced by [Veles Masternodes 2nd gen.](https://github.com/velescore/veles-masternode) (currently experimental).


## Usage
The installation / update will start directly when running following command as **root**:
```bash
source <(curl -s https://raw.githubusercontent.com/velescore/veles-installer/master/masternode.sh)
```

Detailed tutorial can be found on the following page in Veles Core Wiki:

https://github.com/velescore/veles/wiki/Masternode-Setup-Guide

## Supported Linux Distributions
Veles Masternode Installer script can be safely run on any platform, and will work most of modern Linux distributions with **systemd** support. We plan to support sysVinit and OpenRC in a future. 

If your system is not supported, running this script has **no** side effects - thanks to extensive dependency checking, it will simply exit with an error message containing hints onto which commands/packages are missing on your system and how to install them.

### Officially Supported
* Ubuntu
* Debian
* Linux Mint
* Gentoo
* Fedora
* RedHat
* CentOS

### Experimental
* OpenSUSE
* Arch Linux

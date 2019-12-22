Veles Masternode Gen 1 Installer
================================
![Master Build Status](https://img.shields.io/travis/velescore/masternode-installer/master?style=for-the-badge) ![Latest Release](https://img.shields.io/github/tag-pre/velescore/masternode-installer.svg?style=for-the-badge) ![Licence](https://img.shields.io/github/license/velescore/masternode-installer?color=blue&style=for-the-badge) 

https://veles.network

About Veles
------------
Veles Core is an open-source blockchain ecosystem providing services such as decentralized VPN in order to help people to defend their online privacy and free access to an information. 
Backed by unique blockchain with features such dynamic block rewards and halving schedule, independent multi-algo PoW consensus, protected against common issues such as 51% attacks. Designed as multi-tiered network which builds on the concept of self-incentivized Masternodes which provide robust service and governance layer.

Veles Masternode Gen 1
----------------------
This is master branch of official install script for Veles Masternode 1st generation, which is current stable Veles Masternode release until the end of Q1 2020. For latest development version of Veles Masternode and installator visit [Veles Masternode Gen 2](https://github.com/velescore/veles-masternode) repository. 

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

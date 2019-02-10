#!/bin/bash
# version 	v0.1.02
# date    	2019-02-09
# description:	Installation of an Veles masternode
# website:      https://veles.network
# twitter:      https://twitter.com/mdfkbtc
# author:  Veles Core developers
# licence: GNU/GPL 
##########################################################

# Configuration variables
TEMP_PATH=$(mktemp -d)
USER='veles'
CONFIG_FILENAME='veles.conf'
DATADIR_PATH='/home/veles/.veles'
COIN_DAEMON='velesd'
COIN_CLI='veles-cli'
INSTALL_PATH='/usr/local/bin'
COIN_TGZ_URL='https://github.com/Velescore/Veles/releases/download/v0.17.0.21/velesLinux.tar.gz'
COIN_NAME='Veles Core'
COIN_NAME_SHORT='veles'
COIN_PORT=21337
RPC_PORT=21338

# Autodetection
NODEIP=$(curl -s4 api.ipify.org)

# Constatnts
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BBLUE='\033[1;34m'
BYELLOW='\033[1;33m'
NC='\033[0m'
ST="${BGREEN} * ${NC}"
OK="${BLUE}[ ${NC}${BGREEN}ok${NC}${BLUE} ]${NC}"
ERR="${BLUE}[ ${NC}${BRED}"'!!'"${NC}${BLUE} ]${NC}"

function pok() {
  echo -e "${OK}"
}

function perr() {
  echo -e "${ERR}"
  if [ -z $1 ]; then
    echo -e "\n${RED}Done: The installation has been terminated because an error has occured.${NC}"
  else
    echo -e "\n${RED}Error: ${1}\nDone: The installation has been terminated.${NC}"
  fi
  exit 1
}

function check_system() {
  echo -en "${ST} Looking for previous installation ...                                 "
  if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] ; then
    perr "$COIN_NAME is already installed."
  fi
  pok
}

function check_ufw() {
  echo -en "${ST} Checking whether UFW firewall is present ... "
  if [ -f "/sbin/ufw" ] && ufw status | grep -wq 'active'; then 
    echo "yes"
    setup_ufw
  else
    echo "no"
  fi
}

function download_node() {
  echo -en "${ST} Downloading installation archive ...                                  "
  cd $TEMP_PATH >/dev/null 2>&1 || perr "Cannot change to the temporary directory: $TEMP_PATH"
  wget -q $COIN_TGZ_URL || perr "Failed to download installation archive"
  
  archive_name=$(echo $COIN_TGZ_URL | awk -F'/' '{print $NF}')

  tar xvzf $archive_name -C ${INSTALL_PATH}/ >/dev/null 2>&1 || "Failed to extract installation archive $archive_name to ${INSTALL_PATH}"
  pok
  rm -rf $TEMP_PATH >/dev/null 2>&1 || echo -e "\n{$BRED} !   ${YELLOW}Warning: Failed to remove temporary directory: ${TEMP_PATH}${NC}\n"
}

function create_user() {
  echo -e "${ST} Setting up user account ... "
  # our new mnode unpriv user acc is added
  if id "$USER" >/dev/null 2>&1; then
    echo -e "\n{$BRED} !   ${YELLOW}Warning: User account ${YELLOW}${USER}${NC} already exists."                       
  else
    echo -en "${ST}   Creating new user account ${YELLOW}${USER}${NC} ...                                 "
    useradd -m $USER && pok || perr
    # TODO: move to another function
    echo -en "${ST}   Creating new datadir ...                                            "
    su - $USER -c "mkdir ${DATADIR_PATH} >/dev/null 2>&1" || perr	"Failed to create datadir: ${DATADIR_PATH}"
    su - $USER -c "touch ${DATADIR_PATH}/${CONFIG_FILENAME} >/dev/null 2>&1" || perr "Failed to create config file: ${DATADIR_PATH}/${CONFIG_FILENAME}"
    pok
  fi
}

function setup_ufw() {
  echo -en "${ST}   Enabling inbound traffic on TCP port ${BYELLOW}${COIN_PORT}${NC} ...                      "
  ufw allow $COIN_PORT/tcp comment "${COIN_NAME_SHORT} MN port" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw allow ssh comment "SSH" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw limit ssh/tcp >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw default allow outgoing >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw enable >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  pok
}
 
function configure_systemd() {
  echo -en "${ST} Creating systemd service ${BYELLOW}${COIN_NAME_SHORT}${NC} ...                                    "
  cat << EOF > /etc/systemd/system/${COIN_NAME_SHORT}.service && pok || perr
[Unit]
Description=${COIN_NAME_SHORT} service
After=network.target
[Service]
User=$USER
Group=$USER
Type=forking
#PIDFile=$DATADIR_PATH/${COIN_NAME_SHORT}.pid
ExecStart=${INSTALL_PATH}/$COIN_DAEMON -daemon -conf=$DATADIR_PATH/$CONFIG_FILENAME -datadir=$DATADIR_PATH
ExecStop=-${INSTALL_PATH}/${COIN_CLI} -conf=$DATADIR_PATH/$CONFIG_FILENAME -datadir=$DATADIR_PATH stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  echo -en "${ST} Reloading systemctl ...                                               "
  systemctl daemon-reload && pok || perr "Failed to reload systemd daemon (systemctl daemon-reload)"
  echo -en "${ST} Setting up the service to auto-start on system boot ...               "
  systemctl enable ${COIN_NAME_SHORT}.service >/dev/null 2>&1 && pok || perr "Failed to enable systemd servie ${COIN_NAME_SHORT}.service"
  #u $USER;cd $DATADIR_PATH
}

function start_systemd_service() {
  echo -en "${ST} Starting ${BYELLOW}${COIN_NAME_SHORT}${NC} service ...                                            "
  systemctl start "${COIN_NAME_SHORT}.service"
  sleep 1   # just in case
  if [ -n "$(pidof ${COIN_DAEMON})" ]; then
    pok
  else
    perr "Daemon ${COIN_DAEMON} is not running, please investigate. You can start by 
running following commands as root: ${BYELLOW}
systemctl start ${COIN_NAME_SHORT}.service
systemctl status ${COIN_NAME_SHORT}.service
cat ${DATADIR_PATH}/debug.log
${NC}"
  fi
}

function create_config() {
  echo -en "${ST} Generating configuration file ...                                     "
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to write configuration to: $DATADIR_PATH/$CONFIG_FILENAME"
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
port=$COIN_PORT
EOF
}

function create_key() {
  if ! [ $ARG1 == '--nonint' ]; then # skip reading in non-interactive mode
    echo -e "Enter your ${RED}${COIN_NAME_SHORT} Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
    read -e COINKEY
  fi
  if [[ -z "$COINKEY" ]]; then
    echo -en "${ST} Generating masternode private key ...                                 "
    ${INSTALL_PATH}/$COIN_DAEMON -daemon >/dev/null 2>&1
    sleep 30
    if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
      perr "${RED}${COIN_NAME_SHORT} server couldn not start. Check /var/log/syslog for errors.${NC}"
    fi
    COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    if [ "$?" -gt "0" ];then
      echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
      sleep 30
      COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    fi
    ${INSTALL_PATH}/${COIN_CLI} stop >/dev/null 2>&1
  fi
  pok
}

function update_config() {
  echo -en "${ST} Updating configuration file ...                                       "
  sed -i 's/daemon=1/daemon=0/' $DATADIR_PATH/$CONFIG_FILENAME
  cat << EOF >> $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to update config file: $DATADIR_PATH/$CONFIG_FILENAME"
## Config generated by Veles Core script masternode.sh v0.1.02
logintimestamps=1
maxconnections=256
txindex=1
listenonion=0
masternode=1
masternodeaddr=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
EOF
  # Might be useful in the future:
  # bind=$NODEIP, externalip=$NODEIP:$COIN_PORT
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 api.ipify.org))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]; then
    if [ $ARG1 == '--nonint' ]; then
      echo -e "\n{$BRED} !   ${YELLOW}Warning: More than one IPv4 detected but running in non-interactive mode, using the first one ...${NC}\n"
    else
      echo -e "${GREEN}More than one IPv4 detected. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
    fi
  else
    NODEIP=${NODE_IPS[0]}
  fi
}

function print_installed_version() {
  echo -en "${BGREEN}"
  ${INSTALL_PATH}/${COIN_CLI} -version | head -n 1
  echo -en "${NC}"
}

function print_logo() {
  ${INSTALL_PATH}/${COIN_CLI} -version | head -n 6 | tail -n 5   # Current Veles Core ASCII logo
  echo -e "     __  ___ ___   ____ ______ ____ ___   _  __ ____   ___   ____"
  echo -e "    /  |/  // _ | / __//_  __// __// _ \ / |/ // __ \ / _ \ / __/"
  echo -e "   / /|_/ // __ |_\ \   / /  / _/ / , _//    // /_/ // // // _/  "
  echo -e "  /_/  /_//_/ |_|___/  /_/  /___//_/|_|/_/|_/ \____//____//___/  "
}

function print_success_screen() {
  print_logo
  echo -en "\n"
  print_installed_version
  echo -e "\n$COIN_NAME Masternode is up and running listening on port ${BYELLOW}$COIN_PORT${NC}."
  echo -e "Configuration file is: ${BYELLOW}$DATADIR_PATH/$CONFIG_FILENAME${NC}"
  echo -e "Start: ${BYELLOW}systemctl start ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Stop: ${BYELLOW}systemctl stop ${COIN_NAME_SHORT}.service${NC}"
  echo -e "VPS_IP:PORT ${BYELLOW}$NODEIP:$COIN_PORT${NC}"
  echo -e "MASTERNODE PRIVATEKEY is: ${BYELLOW}$COINKEY${NC}"
  echo -e "Please check ${BYELLOW}${COIN_NAME_SHORT}${NC} daemon is running with the following command: ${BYELLOW}systemctl status ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Use ${BYELLOW}${COIN_CLI} masternode status${NC} to check your MN."
  echo -e "For help join discord ${RED}https://discord.gg/P528fGg${NC} ..."
  if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${BYELLOW}Sentinel${NC} is installed in ${RED}$DATADIR_PATH/sentinel${NC}"
  echo -e "Sentinel logs is: ${BYELLOW}$DATADIR_PATH/sentinel.log${NC}"
  fi
}

function install_daemon() {
  create_user
  get_ip
  check_ufw
  create_config
 }

function install_masternode() {
  create_key
  update_config
  configure_systemd
  start_systemd_service
 }


##### Main #####
# Load ze args
if ! [ -z "$1" ]; then
  ARG1="${1}"
else
  ARG1=""
fi

check_system
download_node
install_daemon 
install_masternode
print_success_screen

echo -e "\n${BGREEN}Congratulations, installation was successful.\n"

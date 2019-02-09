#!/bin/bash
# version 	v0.1.02
# date    	2019-02-09
# description:	Installation of an Veles masternode
# website:      https://veles.network
# twitter:      https://twitter.com/mdfkbtc
# author:  Veles Core developers
# licence: GNU/GPL 
##########################################################

TMP_FOLDER=$(mktemp -d)
USER='veles'
CONFIG_FILE='veles.conf'
CONFIGFOLDER='/home/veles/.veles'
COIN_DAEMON='velesd'
COIN_CLI='veles-cli'
COIN_PATH='/usr/local/bin/'
COIN_TGZ='https://github.com/Velescore/Veles/releases/download/v0.17.0.21/velesLinux.tar.gz'
COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='veles'
COIN_PORT=21337
RPC_PORT=21338

NODEIP=$(curl -s4 api.ipify.org)


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

function download_node() {
  echo -en "${ST} Downloading an installation archive ...                               "
  cd $TMP_FOLDER >/dev/null 2>&1 || perr "Cannot change to the temporary directory: $TMP_FOLDER"
  wget -q $COIN_TGZ || perr "Failed to download installation archive"
  tar xvzf $COIN_ZIP -C $COIN_PATH >/dev/null 2>&1 || "Failed to extract installation archive $COIN_ZIP to $COIN_PATH"
  pok
  rm -rf $TMP_FOLDER >/dev/null 2>&1 || echo -e "\n{$BRED} !   ${YELLOW}Warning: Failed to remove temporary directory: ${TMP_FOLDER}${NC}\n"
}

function create_user() {
  echo -e "${ST} Setting up user account ... "
  # our new mnode unpriv user acc is added
  if id "$USER" >/dev/null 2>&1; then
    echo -e "\n{$BRED} !   ${YELLOW}Warning: User account ${BLUE}${USER}${NC} already exists."                       
  else
    echo -en "${ST}   Creating new user account ${BLUE}${USER}${NC} ...                                   "
    useradd -m $USER && pok || perr
    # TODO: move to another function
    echo -en "${ST}   Creating new datadir ...                                              "
    su - $USER -c "mkdir ${CONFIGFOLDER} >/dev/null 2>&1" || perr	"Failed to create datadir: ${CONFIGFOLDER}"
    su - $USER -c "touch ${CONFIGFOLDER}/${CONFIG_FILE} >/dev/null 2>&1" || perr "Failed to create config file: ${CONFIGFOLDER}/${CONFIG_FILE}"
    pok
  fi
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

function setup_ufw() {
  echo -en "${ST}   Enabling inbound traffic on TCP port ${BYELLOW}${COIN_PORT}${NC} ...                      "
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw allow ssh comment "SSH" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw limit ssh/tcp >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw default allow outgoing >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw enable >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  pok
}
 
function configure_systemd() {
  echo -en "${ST} Creating systemd service ${BYELLOW}${COIN_NAME}${NC} ...                                    "
  cat << EOF > /etc/systemd/system/$COIN_NAME.service && pok || perr
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=$USER
Group=$USER
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
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
  systemctl enable $COIN_NAME.service >/dev/null 2>&1 && pok || perr "Failed to enable systemd servie ${COIN_NAME}.service"
  #u $USER;cd $CONFIGFOLDER
  

}

function start_systemd_service() {
  echo -en "${ST} Starting ${BYELLOW}${COIN_NAME}${NC} service ...                                            "
  systemctl start $COIN_NAME.service && $(sleep 1 ; pok) || perr "Failed to start systemd service ${COIN_NAME}.service"

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start${NC} $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function create_config() {
  echo -en "${ST} Generating configuration file ...                                     "
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE && pok || perr "Failed to write configuration to: $CONFIGFOLDER/$CONFIG_FILE"
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
    echo -e "Enter your ${RED}$COIN_NAME Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
    read -e COINKEY
  fi
  if [[ -z "$COINKEY" ]]; then
    echo -en "${ST} Generating masternode private key ...                                 "
    $COIN_PATH$COIN_DAEMON -daemon >/dev/null 2>&1
    sleep 30
    if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
      perr "${RED}$COIN_NAME server couldn not start. Check /var/log/syslog for errors.${NC}"
    fi
    COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
    if [ "$?" -gt "0" ];then
      echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
      sleep 30
      COINKEY=$($COIN_PATH$COIN_CLI masternode genkey)
    fi
    $COIN_PATH$COIN_CLI stop >/dev/null 2>&1
  fi
  pok
}

function update_config() {
  echo -en "${ST} Updating configuration file ...                                       "
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE && pok || perr "Failed to update config file: $CONFIGFOLDER/$CONFIG_FILE"
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

function check_environment() {
  echo -en "${ST} Checking the installation environment ...                             "
  if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
    perr "${RED}$COIN_NAME is already installed.${NC}"
  fi
  pok
}


function important_information() {
 echo -e "\n==================================================================================================================="
 echo -e "${RED} _   __ ____ __    ____ ____   __  ___ ___    ____ ______ ____ ___   _  __ ____   ___   ____ ${NC}  "
 echo -e "${RED}| | / // __// /   / __// __/  /  |/  // _ |  / __//_  __// __// _ \ / |/ // __ \ / _ \ / __/ ${NC} "
 echo -e "${RED}| |/ // _/ / /__ / _/ _\ \   / /|_/ // __ | _\ \   / /  / _/ / , _//    // /_/ // // // _/  ${NC} "
 echo -e "${RED}|___//___//____//___//___/  /_/  /_//_/ |_|/___/  /_/  /___//_/|_|/_/|_/ \____//____//___/ ${NC} "
 echo -e "                                                                                            "
 echo -e "==================================================================================================================="
 echo -e "$COIN_NAME Masternode is up and running listening on port ${GREEN}$COIN_PORT${NC}."
 echo -e "Configuration file is: ${GREEN}$CONFIGFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${GREEN}systemctl start $COIN_NAME.service${NC}"
 echo -e "Stop: ${GREEN}systemctl stop $COIN_NAME.service${NC}"
 echo -e "VPS_IP:PORT ${GREEN}$NODEIP:$COIN_PORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${GREEN}$COINKEY${NC}"
 echo -e "Please check ${GREEN}$COIN_NAME${NC} daemon is running with the following command: ${GREEN}systemctl status $COIN_NAME.service${NC}"
 echo -e "Use ${GREEN}$COIN_CLI masternode status${NC} to check your MN."
 echo -e "For help join discord ${RED}https://discord.gg/P528fGg${NC} ..."
 if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${GREEN}Sentinel${NC} is installed in ${RED}$CONFIGFOLDER/sentinel${NC}"
  echo -e "Sentinel logs is: ${GREEN}$CONFIGFOLDER/sentinel.log${NC}"
 fi
 echo -e "==================================================================================================================="
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
  important_information
  configure_systemd
 }


##### Main #####
# Load ze args
if ! [ -z "$1" ]; then
  ARG1="${1}"
else
  ARG1=""
fi

check_environment
download_node
install_daemon 
install_masternode

echo -e "\n${BGREEN}Congratulations, installation was successful.\n"

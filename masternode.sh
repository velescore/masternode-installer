#!/bin/bash
# version 	v0.1.03
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
START_STOP_TIMEOUT=14
START_STOP_RETRY_TIMEOUT=5
KEY_GEN_TIMEOUT=15

# Autodetection
NODEIP=$(curl -s4 api.ipify.org)
NEED_REINDEX=""

# Constatnts
SCRIPT_VERSION='v0.1.04'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BBLUE='\033[1;34m'
BYELLOW='\033[1;33m'
NC='\033[0m'
ST="${BGREEN} *${NC}"
OK="${BLUE}[ ${NC}${BGREEN}ok${NC}${BLUE} ]${NC}"
ERR="${BLUE}[ ${NC}${BRED}"'!!'"${NC}${BLUE} ]${NC}"

function pok() {
  echo -e "${OK}"
}

function perr() {
  echo -e "${ERR}"
  if [ -z "${1}" ]; then
    echo -e "\n${RED}Done: The installation has been terminated because an error has occured.${NC}"
  else
    echo -e "\n${RED}Error: ${1}\nDone: The installation has been terminated.${NC}"
  fi
  exit 1
}

function check_installation() {
  echo -en "\n${ST} Checking whether ${COIN_NAME} is already installed ... "
  #if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] ; then
  if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] ; then
    echo "yes"
    start_update
  else
    echo "no"
    start_installation
  fi
}

function check_ufw() {
  echo -en "${ST}   Checking whether UFW firewall is present ... "
  if [ -f "/sbin/ufw" ] && ufw status | grep -wq 'active'; then 
    echo "yes"
    setup_ufw
  else
    echo "no"
  fi
}

function download_and_copy() {
  echo -en "${ST}   Downloading installation archive ...                                "
  cd $TEMP_PATH >/dev/null 2>&1 || perr "Cannot change to the temporary directory: $TEMP_PATH"
  wget -q $COIN_TGZ_URL || perr "Failed to download installation archive"

  # Extract executables to the temporary directory
  archive_name=$(echo $COIN_TGZ_URL | awk -F'/' '{print $NF}')
  tar xvzf $archive_name -C ${TEMP_PATH} >/dev/null 2>&1 || perr "Failed to extract installation archive ${archive_name}"

  # Check whether destination files are already installed
  #if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ] && [ -e "${INSTALL_PATH}/${COIN_CLI}" ] \
  #  && [ "$(md5sum ${TEMP_PATH}/${COIN_DAEMON})" == "$(md5sum ${INSTALL_PATH}/${COIN_DAEMON})" ] \
  #  && [ "$(md5sum ${TEMP_PATH}/${COIN_CLI})" == "$(md5sum ${INSTALL_PATH}/${COIN_CLI})" ]; then
  #  echo
  #  print_installed_version
  #  echo -e "\n${BGREEN}Congratulations, you have the latest version of ${COIN_NAME} already installed.\n"
  #fi
  
  # Remove if destination files already exist
  if [ -e "${INSTALL_PATH}/${COIN_DAEMON}" ]; then
    rm "${INSTALL_PATH}/${COIN_DAEMON}" || perr "Failed to remove old version of ${COIN_DAEMON}"
  fi
  if [ -e "${INSTALL_PATH}/${COIN_CLI}" ]; then
    rm "${INSTALL_PATH}/${COIN_CLI}" || perr "Failed to remove old version of ${COIN_CLI}"
  fi

  # Copy the files to installation directory and ensure executable flags
  cp "${TEMP_PATH}/${COIN_DAEMON}" "${INSTALL_PATH}/${COIN_DAEMON}" || "Failed to copy ${COIN_DAEMON} to ${INSTALL_PATH}"
  cp "${TEMP_PATH}/${COIN_CLI}" "${INSTALL_PATH}/${COIN_CLI}" || "Failed to copy ${COIN_CLI} to ${INSTALL_PATH}"
  chmod +x "${INSTALL_PATH}/${COIN_DAEMON}" || "Failed to set exacutable flag for ${INSTALL_PATH}/${COIN_DAEMON}"
  chmod +x "${INSTALL_PATH}/${COIN_CLI}" || "Failed to set exacutable flag for ${INSTALL_PATH}/${COIN_CLI}"

  pok

  rm -rf $TEMP_PATH >/dev/null 2>&1 || echo -e "\n${BYELLOW} !   ${YELLOW}Warning: Failed to remove temporary directory: ${TEMP_PATH}${NC}\n"
  cd -
}

function create_user() {
  echo -e "${ST}   Setting up user account ... "
  # our new mnode unpriv user acc is added
  if id "$USER" >/dev/null 2>&1; then
    echo -e "\n${BYELLOW} !   ${BYELLOW}Warning: User account ${BYELLOW}${USER}${NC} already exists."                       
  else
    echo -en "${ST}     Creating new user account ${YELLOW}${USER}${NC} ...                               "
    useradd -m $USER && pok || perr
    # TODO: move to another function
    echo -en "${ST}     Creating new datadir ...                                          "
    su - $USER -c "mkdir ${DATADIR_PATH} >/dev/null 2>&1" || perr	"Failed to create datadir: ${DATADIR_PATH}"
    su - $USER -c "touch ${DATADIR_PATH}/${CONFIG_FILENAME} >/dev/null 2>&1" || perr "Failed to create config file: ${DATADIR_PATH}/${CONFIG_FILENAME}"
    pok
  fi
}

function setup_ufw() {
  echo -en "${ST}     Enabling inbound traffic on TCP port ${BYELLOW}${COIN_PORT}${NC} ...                    "
  ufw allow $COIN_PORT/tcp comment "${COIN_NAME_SHORT} MN port" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw allow ssh comment "SSH" >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw limit ssh/tcp >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw default allow outgoing >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  ufw enable >/dev/null 2>&1 || perr "Failed to set-up UFW (ufw allow $COIN_PORT/tcp)"
  pok
}
 
function configure_systemd() {
  echo -en "${ST}   Creating systemd service ${BYELLOW}${COIN_NAME_SHORT}${NC} ...                                  "
  cat << EOF > /etc/systemd/system/${COIN_NAME_SHORT}.service && pok || perr "Failed to create systemd service"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
[Unit]
Description=${COIN_NAME_SHORT} service
After=network.target
[Service]
User=$USER
Group=$USER
Type=forking
#PIDFile=$DATADIR_PATH/${COIN_NAME_SHORT}.pid
ExecStart=${INSTALL_PATH}/${COIN_DAEMON} -daemon -conf=$DATADIR_PATH/$CONFIG_FILENAME -datadir=$DATADIR_PATH
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

  echo -en "${ST}   Reloading systemctl ...                                             "
  systemctl daemon-reload && pok || perr "Failed to reload systemd daemon [systemctl daemon-reload]"
  echo -en "${ST}   Setting up the service to auto-start on system boot ...             "
  systemctl enable ${COIN_NAME_SHORT}.service >/dev/null 2>&1 && pok || perr "Failed to enable systemd servie ${COIN_NAME_SHORT}.service"
  #u $USER;cd $DATADIR_PATH
}

function start_service() {
  echo -en "${ST}   Starting ${COIN_NAME_SHORT}.service ...                                          "
  systemctl start "${COIN_NAME_SHORT}.service" || tries=${START_STOP_TIMEOUT}
  tries=0

  # Wait until we see the proccess running, or until timeout
  while ! ps aux | grep -v grep | grep "${INSTALL_PATH}/${COIN_DAEMON}" > /dev/null && [ ${tries} -lt ${START_STOP_TIMEOUT} ]; do
    sleep 5
    ((tries++))

    # Try to launch again if waiting for too long
    if (( $tries % $START_STOP_RETRY_TIMEOUT == 0 )); then
      echo -en "\n${BYELLOW} !   ${YELLOW}Warning: Service is starting up longer than usual, retrying ...     "
      systemctl restart "${COIN_NAME_SHORT}.service" > /dev/null
    fi
  done

  if [ ${tries} -eq ${START_STOP_TIMEOUT} ]; then
    perr "Service ${COIN_NAME_SHORT}.service failed to start (timeout), ${COIN_DAEMON} is not running,
${RED}please investigate. You can begin by checking output of following commands as root:
${YELLOW}systemctl start ${COIN_NAME_SHORT}.service
${NC}"$(systemctl start ${COIN_NAME_SHORT}.service)"
${YELLOW}systemctl status ${COIN_NAME_SHORT}.service
${NC}"$(systemctl status ${COIN_NAME_SHORT}.service)"
${YELLOW}cat ${DATADIR_PATH}/debug.log
${NC}"$(cat ${DATADIR_PATH}/debug.log | tail -n 10)"
...
"
  else
    pok
  fi
}

function stop_service() {
  echo -en "${ST}   Stopping ${COIN_NAME_SHORT}.service ...                                          "
  systemctl stop "${COIN_NAME_SHORT}.service" || perr "Service ${COIN_NAME_SHORT} failed to stop."
  tries=0

  # Wait until we NOT see the proccess running, or until timeout
  while ps aux | grep -v grep | grep "${INSTALL_PATH}/${COIN_DAEMON}" > /dev/null && [ ${tries} -lt ${START_STOP_TIMEOUT} ]; do
    sleep 1
    ((tries++))
  done

  if [ ${tries} -eq ${START_STOP_TIMEOUT} ]; then
    perr "Service ${COIN_NAME_SHORT} failed to stop."
  else
    pok
  fi
}

function enable_reindex_next_start() {
  # reindex after update
  echo -en "${ST}   Scheduling database reindex on next start ...                       "
  sed -i.bak "s/-daemon -conf/-daemon -reindex -conf/g" "/etc/systemd/system/${COIN_NAME_SHORT}.service" || "Failed to update systemd service configuration"
  systemctl daemon-reload && pok || "Failed to reload systemd daemon"
}

function disable_reindex_next_start() {
  sed -i.bak "s/-daemon -reindex -conf/-daemon -conf/g" "/etc/systemd/system/${COIN_NAME_SHORT}.service" || "Failed to update systemd service configuration"
  systemctl daemon-reload || "Failed to reload systemd daemon"
}


function create_config() {
  echo -en "${ST}   Generating configuration file ...                                   "
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to write configuration to: $DATADIR_PATH/$CONFIG_FILENAME"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
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
    echo -en "${ST}   Generating masternode private key ...                               "
    ${INSTALL_PATH}/$COIN_DAEMON -daemon >/dev/null 2>&1
    sleep ${KEY_GEN_TIMEOUT}
    if [ -z "$(ps axo cmd:100 | grep $COIN_DAEMON)" ]; then
      perr "${RED}${COIN_NAME_SHORT} server couldn not start. Check /var/log/syslog for errors.${NC}"
    fi
    COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    if [ "$?" -gt "0" ];then
      echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the Private Key${NC}"
      sleep $((KEY_GEN_TIMEOUT * 2))
      COINKEY=$(${INSTALL_PATH}/${COIN_CLI} masternode genkey)
    fi
    ${INSTALL_PATH}/${COIN_CLI} stop >/dev/null 2>&1
  fi
  pok
}

function update_config() {
  echo -en "${ST}   Updating configuration file ...                                     "
  sed -i 's/daemon=1/daemon=0/' $DATADIR_PATH/$CONFIG_FILENAME
  cat << EOF >> $DATADIR_PATH/$CONFIG_FILENAME && pok || perr "Failed to update config file: $DATADIR_PATH/$CONFIG_FILENAME"
## Generated by Veles Core script masternode.sh ${SCRIPT_VERSION}
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
      echo -e "\n${BYELLOW} !   ${YELLOW}Warning: More than one IPv4 detected but running in non-interactive mode, using the first one ...${NC}\n"
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
  ${INSTALL_PATH}/${COIN_DAEMON} -version | head -n 1
  echo -en "${NC}"
}

function print_logo() {
  echo -e ' ____   ____     .__                _________                       
_\___\_/___/____ |  |   ____   _____\_   ___ \  ___________   ____  
\___________/__ \|  | _/ __ \ /  ___/    \  \/ /  _ \_  __ \_/ __ \ 
   \  Y  /\  ___/|  |_\  ___/ \___ \\     \___(  <_> )  | \/\  ___/ 
    \___/  \___  >____/\___  >____  >\______  /\____/|__|    \___  >
     __  ___ ___   ____ ______ ____ ___   _| /_ ____   ___   ____
    /  |/  // _ | / __//_  __// __// _ \ / |/ // __ \ / _ \ / __/
   / /|_/ // __ |_\ \   / /  / _/ / , _//    // /_/ // // // _/  
  /_/  /_//_/ |_|___/  /_/  /___//_/|_|/_/|_/ \____//____//___/  '
}

function print_install_notice() {
  echo -e "${ST} ${BGREEN}Done.${NC}\n"
  print_installed_version
  echo -e "\n$COIN_NAME Masternode is up and running listening on port ${BYELLOW}$COIN_PORT${NC}."
  echo -e "Configuration file is: ${BYELLOW}$DATADIR_PATH/$CONFIG_FILENAME${NC}"
  echo -e "VPS_IP:PORT ${BYELLOW}$NODEIP:$COIN_PORT${NC}"
  echo -e "MASTERNODE PRIVATEKEY is: ${BYELLOW}$COINKEY${NC}"
  print_usage_notice
}

function print_update_notice() {
  echo -e "${ST} ${BGREEN}Done.${NC}\n"
  print_installed_version
  echo -e "\n$COIN_NAME Masternode is up and running on the latest offical version."
  print_usage_notice
}

function print_usage_notice() {
  echo -e "Start: ${BYELLOW}systemctl start ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Stop: ${BYELLOW}systemctl stop ${COIN_NAME_SHORT}.service${NC}"
  echo -e "You can always check whether ${BYELLOW}${COIN_NAME_SHORT}${NC} daemon is running "
  echo -e "with the following command: ${BYELLOW}systemctl status ${COIN_NAME_SHORT}.service${NC}"
  echo -e "Use ${BYELLOW}${COIN_CLI} masternode status${NC} to check your MN."
  echo -e "For help join discord ${RED}https://discord.gg/P528fGg${NC} ..."
  if [[ -n $SENTINEL_REPO  ]]; then
  echo -e "${BYELLOW}Sentinel${NC} is installed in ${RED}$DATADIR_PATH/sentinel${NC}"
  echo -e "Sentinel logs is: ${BYELLOW}$DATADIR_PATH/sentinel.log${NC}"
  fi
}

function configure_daemon() {
  create_user
  get_ip
  check_ufw
  create_config
  configure_systemd
 }

function install_masternode() {
  create_key
  update_config
 }

function start_installation() {
  echo -e "${ST} Starting ${COIN_NAME} installation..."
  download_and_copy
  configure_daemon 
  install_masternode
  start_service
  print_install_notice
  echo -e "\n${BGREEN}Congratulations, ${COIN_NAME} has been installed successfuly.\n"
}

function start_update() {
  echo -e "${ST} Starting ${COIN_NAME} update ..."
  stop_service
  download_and_copy
  enable_reindex_next_start
  start_service
  disable_reindex_next_start
  print_update_notice
  echo -e "\n${BGREEN}Congratulations, ${COIN_NAME} has been updated successfuly.\n"
}


##### Main #####
# Load ze args
if ! [ -z "$1" ]; then
  ARG1="${1}"
else
  ARG1=""
fi

if [ "${ARG1}" == "--nonint" ]; then
  echo -e "\n[ $0: Running in non-interactive mode, increasing timeout settings ]"
  # Increase timeouts when in non-interactive mode
  START_STOP_TIMEOUT=$((START_STOP_TIMEOUT * 2))
  START_STOP_RETRY_TIMEOUT=$((START_STOP_RETRY_TIMEOUT * 2))
  KEY_GEN_TIMEOUT=$((KEY_GEN_TIMEOUT * 2))
fi

print_logo
check_installation

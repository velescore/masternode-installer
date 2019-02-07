#!/bin/bash
# version 	    v0.2
# date    	    2019-01-22
# Function: 	  Daemon update of an Veles masternode.
# authors: 	    Mdfkbtc, AltcoinBaggins
# website:      https://veles.network
# twitter:      https://twitter.com/mdfkbtc, https://twitter.com/AltcoinBaggins
# license:      GNU/GPL
##########################################################
COIN_SVC_NAME='veles'
USER='veles'
COIN_DAEMON='velesd'
COIN_CLI='veles-cli'
COIN_BIN_PATH='/usr/local/bin/'
COIN_TEMP_PATH="/tmp/.VelescoreUpdate.v017/"
COIN_TGZ_NAME='velesLinux.tar.gz'
COIN_TGZ=$(echo $COIN_TGZ_NAME | awk -F'/' '{print $NF}')
DAEMON_LATEST="https://api.github.com/repos/Velescore/Veles"
#LATEST_VERSION=$(curl -s "http://explorer.veles.network/release/velesLinux.currentVersion")
#SHA256_SUM_URL="http://explorer.veles.network/release/velesLinux.sha256sum"
#MD5_SUM_URL="http://explorer.veles.network/release/velesLinux.md5sum"
DOWNLOAD_URL="https://github.com/Velescore/Veles/releases/download/v0.17.0.21/velesLinux.tar.gz"
# Prettier output
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
STAR="${GREEN}*${NC}"

function exit_with_error()
{
  if [ $# -gt 0 ]; then
    printf "\n\n${RED}ERROR:${NC} $@ ${RED} !!! ${NC}\n\n"
  fi
  exit 1
}

function do_sanity_checks() {
  ls /etc/systemd/* | grep "${COIN_SVC_NAME}.service" > /dev/null || exit_with_error "Service ${COIN_SVC_NAME} does not exist, masternode was not installed from Veles masternode script."
  ls "${COIN_BIN_PATH}" | grep "${COIN_DAEMON}" > /dev/null  || exit_with_error "Cannot locate file ${COIN_BIN_PATH}${COIN_DAEMON}, is Veles daemon already installed?"
  ls "${COIN_BIN_PATH}" | grep "${COIN_CLI}" > /dev/null  || exit_with_error "Cannot locate file ${COIN_BIN_PATH}${COIN_DAEMON}, is Veles cli utility already installed?"
}

function remove_old_daemon() {
  rm "${COIN_BIN_PATH}${COIN_CLI}" || exit_with_error "Failed to uninstall previous version of velesd from ${COIN_BIN_PATH}"
  rm "${COIN_BIN_PATH}${COIN_DAEMON}" || exit_with_error "Failed to uninstall previous version of veles-cli from ${COIN_BIN_PATH}"
}

function install_new_daemon() {
  cp "${COIN_TEMP_PATH}${COIN_CLI}" "${COIN_BIN_PATH}${COIN_CLI}" || exit_with_error "Failed to copy new version of velesd to the install path ${COIN_BIN_PATH}"
  cp "${COIN_TEMP_PATH}${COIN_DAEMON}" "${COIN_BIN_PATH}${COIN_DAEMON}" || exit_with_error "Failed to copy new version of veles-cli to the install path ${COIN_BIN_PATH}"
}

#function verify_hashes() {
  #cd ${COIN_TEMP_PATH} && wget "${SHA256_SUM_URL}" >/dev/null 2>&1 && wget "${MD5_SUM_URL}" >/dev/null 2>&1 || exit_with_error "Unable to download checksum files"
  #echo "  Checking SHA256 hashes ..."
  #cd ${COIN_TEMP_PATH} && sha256sum -c "velesLinux.sha256sum" || exit_with_error "SHA256 checksum verification failed"
 # cd ${COIN_TEMP_PATH} && md5sum -c "velesLinux.md5sum" || exit_with_error "MD5 checksum verification failed"
#}

function download_node() {
  [[ -d "${COIN_TEMP_PATH}" ]] || mkdir "${COIN_TEMP_PATH}" || exit_with_error "Unable to create temporary path: ${COIN_TEMP_PATH}"
  cd ${COIN_TEMP_PATH} && wget "${DOWNLOAD_URL}" || exit_with_error "Unable to download installation archive"
  cd ${COIN_TEMP_PATH} && tar xvzf "./${COIN_TGZ_NAME}" >/dev/null 2>&1 || exit_with_error "Unable extract installation archive"
}

function enable_reindex_next_start() {
  # reindex after update
  sed -i.bak "s/-daemon -conf/-daemon -reindex -conf/g" /etc/systemd/system/veles.service
  systemctl daemon-reload
}

function disable_reindex_next_start() {
  sed -i.bak "s/-daemon -reindex -conf/-daemon -conf/g" /etc/systemd/system/veles.service
  systemctl daemon-reload
}

function start_service() {
  systemctl start "${COIN_SVC_NAME}" || exit_with_error "Unable to start the service: ${COIN_SVC_NAME}"
}

function stop_service() {
  su "${USER}" -c "${COIN_BIN_PATH}${COIN_CLI} stop"
  systemctl stop "${COIN_SVC_NAME}" || echo "WARNING: Unable to stop the service: ${COIN_SVC_NAME}"
  sleep 1
}

function cleanup() {
  rm -rf "${COIN_TEMP_PATH}"
}

function print_daemon_version() {
  su "${USER}" -c "${COIN_BIN_PATH}${COIN_DAEMON} -version"
}

##### Main #####
#clear

#clear
echo "Starting Veles Core update task ..."
printf "${RED}
 ____   ____     .__                _________                       
_\___\_/___/____ |  |   ____   _____\_   ___ \  ___________   ____  ${YELLOW}
\___________/__ \|  | _/ __ \ /  ___/    \  \/ /  _ \_  __ \_/ __ \ 
   \  Y  /\  ___/|  |_\  ___/ \___ \\     \___(  <_> )  | \/\  ___/ ${RED}
    \___/  \___  >____/\___  >____  >\______  /\____/|__|    \___  >
               \/          \/     \/        \/                   \/ 
${NC}"
printf "${STAR} Checking whether Veles service and daemon are correctly installed ..."
do_sanity_checks
cleanup
printf "\n${STAR} Stopping Veles service ..."
stop_service
printf "\n${STAR} Downloading new daemon ..."
download_node
#printf "\n${STAR} Verifying the downlaoded files ..."
#verify_hashes
printf "\n${STAR} Removing old daemon ..."
remove_old_daemon
printf "\n${STAR} Installing new daemon ..."
install_new_daemon
cleanup
printf "\n${STAR} Starting Veles service ..."
disable_reindex_next_start
start_service
disable_reindex_next_start
printf "\n${STAR} Your newly installed Veles Core version is:"
print_daemon_version
printf "\n${GREEN}Congratulations, your Veles Core has been succesfully updated!${NC}\n"

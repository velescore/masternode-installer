ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SYSD_TOOL_URL=https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh
DAEMON_NAME=velesd

test:
	make prepare
	@echo '[test] Running the script [install mode] ...'
	sudo ./masternode.sh --nonint
	@echo '[test] Done: Installation finished, checking whether daemon is running ...'
	@ps aux | grep -v grep | grep velesd || exit 1
	@echo '[test] Running the script [update mode] ...'
	sudo ./masternode.sh --nonint
	@echo '[test] Done: Update finished, checking whether daemon is running ...'
	@ps aux | grep -v grep | grep velesd || exit 1
	@make clean

test_as_root:
	make prepare
	make docker_fix_systemd
	@echo '[test] Running the script [install mode] ...'
	./masternode.sh --nonint
	@echo '[test] Done: Installation finished, checking whether daemon is running ...'
	@ps aux | grep -v grep | grep velesd || exit 1
	@echo '[test] Running the script [update mode] ...'
	./masternode.sh --nonint
	@echo '[test] Done: Update finished, checking whether daemon is running ...'
	@ps aux | grep -v grep | grep velesd || exit 1
	@make clean

prepare:
	@echo '[test] Preparing the tests ...'
	wget --quiet $(ASSERT_TOOL_URL) || exit 1
	chmod +x assert.sh || exit 1

docker_fix_systemd:
	wget --quiet $(SYSD_TOOL_URL) || exit 1
	cp systemctl.py /usr/bin/systemctl
	chmod +x /usr/bin/systemctl
	if ! [ -d "/etc/systemd/system" ]; then mkdir -p "/etc/systemd/system" ; fi

clean:
	echo "[test] Cleaning up ..."
	@rm assert.sh
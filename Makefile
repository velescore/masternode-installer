ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SYSD_TOOL_URL=https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh
DAEMON_NAME=velesd

test_install:
	@echo -n '[test_install] Running the masternode script ...'
	./masternode.sh --nonint
	@echo '[test_install] Done: Masternode script finished with success.'
	@echo -n '[test_install] Checking whether Veles Core daemon is running ... '
	@ps aux | grep -v grep | grep velesd && echo 'success' || exit 1

docker_test_install:
	
	@make get_docker_systemd
	@echo '[docker_test_install] Starting the test ...'
	@make test_install

get_assertion_tool:
	@echo '[test] Installing assertion toolkit ...'
	@[ -f assert.sh ] || wget --quiet $(ASSERT_TOOL_URL) || exit 1
	@[ -x assert.sh ] || chmod +x assert.sh || exit 1

get_docker_systemd:
	@echo '[test] Installing custom Docker systemd ...'
	@[ -f systemctl.py ] || wget --quiet $(SYSD_TOOL_URL) || exit 1
	@[ -x systemctl.py ] || chmod +x systemctl.py || exit 1
	@mv systemctl.py /usr/bin/systemctl || exit 1
	@[ -d "/etc/systemd/system" ] || mkdir -p "/etc/systemd/system" || exit 1

clean:
	echo "[test] Cleaning up ..."
	@rm assert.sh
	@rm assert.sh
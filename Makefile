ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SYSD_TOOL_URL=https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh
DAEMON_NAME=velesd

test_install:
	make test_dependencies
	@echo -n '[test_install] Running the masternode script ...'
	./masternode.sh --nonint
	@echo '[test_install] Done: Masternode script finished with success.'
	@echo -n '[test_install] Checking whether Veles Core daemon is running ... '
	@ps aux | grep -v grep | grep velesd > /dev/null && echo 'success' || exit 1
	@echo -e "[test_install] Done [success] \n"

docker_test_install:
	@make get_docker_systemd
	@echo '[docker_test_install] Starting the test ...'
	@make test_install
	@echo -e "[docker_test_install] Done [success] \n"

test_dependencies:
	@echo '[test_dependencies] Starting the test ...'
	@echo -n "Checking whether ifconfig command is present ... "
	@command -v ifconfig >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether ip command is present ... "
	@command -v ip >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether netstat command is present ... "
	@command -v netstat >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether curl command is present ... "
	@command -v curl >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether wget command is present ... "
	@command -v wget >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether sed command is present ... "
	@command -v sed >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether awk command is present ... "
	@command -v awk >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether basename command is present ... "
	@command -v basename >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether apt-get package manager is present ... "
	@command -v apt-get >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether yum package manager is present ... "
	@command -v yum >/dev/null 2>&1  && echo "yes" || echo "no"
	@echo -n "Checking whether systemd is installed ... "
	@command -v systemctl >/dev/null 2>&1  && echo 'yes' || (echo "no, but is required!" ; exit 1)
	@echo -e "[test_dependencies] Done [success] \n"

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

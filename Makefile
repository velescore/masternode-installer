ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh
DAEMON_NAME=velesd

test:
	make prepare
	@echo '[test] Running the script [install mode] ...'
	sudo ./masternode.sh --nonint
	@echo '[test] Done: Installation finished, checking whether daemon is running ...'
	@ps aux | grep velesd || exit 1
	@echo '[test] Running the script [update mode] ...'
	sudo ./masternode.sh --nonint
	@echo '[test] Done: Update finished, checking whether daemon is running ...'
	@ps aux | grep velesd || exit 1
	@make clean

prepare:
	@echo '[test] Preparing the tests ...'
	@wget --quiet $(ASSERT_TOOL_URL) || exit 1
	@chmod +x assert.sh || exit 1

clean:
	echo "[test] Cleaning up ..."
	@grm assert.sh
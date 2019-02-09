ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh

test:
	make prepare
	@echo '[test] Running the script ...'
	sudo ./masternode.sh --nonint
	@echo '[test] Done: Script has finished.'
	make clean

prepare:
	@echo '[test] Preparing the tests ...'
	@wget --quiet $(ASSERT_TOOL_URL) || exit 1
	@chmod +x assert.sh || exit 1

clean:
	echo "[test] Cleaning up ..."
	rm assert.sh
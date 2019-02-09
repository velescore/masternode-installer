ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh
SCRIPT_URL=https://raw.githubusercontent.com/Velescore/veles-masternode-install/master/masternode.sh

test:
	echo 'Donwloading assertion tool ...'
	wget --quiet $(ASSERT_TOOL_URL) || exit 1
	chmod +x assert.sh || exit 1
	sudo ./masternode.sh --nonint
	make clean

download_installer:
	#echo "Downloading masternode install script ..."
	#wget --quiet $(SCRIPT_URL) || exit 1
	#chmod +x masternode.sh
	#./assert.sh "echo 1" "1"

clean:
	echo "Cleaning up ..."
	rm assert.sh
ASSERT_TOOL_URL=https://raw.github.com/lehmannro/assert.sh/v1.1/assert.sh

test:
	wget $(ASSERT_TOOL_URL)
	@chmod +x assert.sh
	./assert.sh "echo 1" "1"
	@rm assert.sh

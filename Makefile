TEST_OS := archlinux debian ubuntu fedora redhat/ubi10 opensuse/leap opensuse/tumbleweed zzsrv/openwrt
TEST_DIR := tests
TEST_LOG := ci.log
TEST_TOOL := bats

.PHONY: help
help: ## Print help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: prepare ci cd ## Make all targets

.PHONY: prepare
prepare: $(TEST_TOOL) ## Prepare all needed tools and libraries

bats: ## Install BATS test framework
	git clone https://github.com/bats-core/bats-core.git $@ 2>&1 | tee -a $(TEST_LOG)

.PHONY: ci build test package
ci: build test package ## Run CI test locally

build: prepare # add actions as needed

# .PHONY: $(TEST_OS)
test: build $(TEST_OS) ## Run test in all OS

$(TEST_OS): bats ## Run test in specific OS
	@echo "========== Action start at $$(date '+%Y-%m-%d %H:%M:%S') in $@ ==========" 2>&1 | tee -a $(TEST_LOG)
	@docker run -it --rm -v .:/repo -w /repo $@ bash -c "\
		export CI=true && \
		export PATH=\$$PATH:/repo/bin:/repo/bats/bin && \
		mirror-set $@ && \
		pmp self-install && \
		git config --global user.email test@example.com && \
		git config --global user.name test && \
		pmp install make && \
		make test-all \
		" 2>&1 | tee -a $(TEST_LOG)
	@echo "========== Action done at $$(date '+%Y-%m-%d %H:%M:%S') in $@  ==========" 2>&1 | tee -a $(TEST_LOG)

.PHONY: test-all $(TEST_DIR)
test-all: $(TEST_DIR) ## Test the whole project

$(TEST_DIR):
	$(MAKE) -C $@

package: test # add actions as needed

.PHONY: cd release deploy 
cd: release deploy ## Run CD actions locally

release: package # add actions as needed

deploy: release # add actions as needed

.PHONY: clean
clean: ## Clean all make outputs
	rm -rf $(TEST_LOG) $(TEST_TOOL)

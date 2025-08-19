SHELL := /bin/bash
LOG_FILE := ci.log

TEST_IMGS := archlinux debian ubuntu fedora redhat/ubi10 opensuse/leap opensuse/tumbleweed zzsrv/openwrt
TEST_DIRS := tests
DEP_TOOLS := bats

.PHONY: help
help: ## Print help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' |\
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: all
all: prepare ci cd ## Make all targets

.PHONY: prepare
prepare: $(DEP_TOOLS) ## Prepare all needed tools and libraries

bats: ## Install BATS test framework
	git clone https://github.com/bats-core/bats-core.git $@ 2>&1 | tee -a $(LOG_FILE)

.PHONY: ci build test package
ci: build test package ## Run CI test locally

build: prepare # add actions as needed

# .PHONY: $(TEST_IMGS)
test: build $(TEST_IMGS) ## Run test in all OS

$(TEST_IMGS): bats ## Run test in specific OS
	@echo "========== Action start at $$(date '+%Y-%m-%d %H:%M:%S') in $@ ==========" 2>&1 | tee -a $(LOG_FILE)
	$(shell command -v docker || command -v podman || echo no-cmd) run -it --rm -v .:/repo -w /repo $@ bash -c "\
		export CI=true && \
		export PATH=\$$PATH:/repo/bin:/repo/bats/bin && \
		mirror-set $@ && \
		pmp self-install && \
		git config --global user.email test@example.com && \
		git config --global user.name test && \
		pmp install -y make && \
		make test-all \
		" 2>&1 | tee -a $(LOG_FILE)
	@echo "========== Action done at $$(date '+%Y-%m-%d %H:%M:%S') in $@  ==========" 2>&1 | tee -a $(LOG_FILE)

.PHONY: test-all $(TEST_DIRS)
test-all: $(TEST_DIRS) ## Test the whole project

$(TEST_DIRS):
	$(MAKE) -C $@

package: test # add actions as needed

.PHONY: cd release deploy 
cd: release deploy ## Run CD actions locally

release: package # add actions as needed

deploy: release # add actions as needed

.PHONY: clean
clean: ## Clean all make outputs
	-rm -rf $(LOG_FILE) $(DEP_TOOLS)

.PHONY: all
all: help

.PHONY: help
help: ## Print help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: tests ## Test the whole project
	@for dir in $^; do $(MAKE) -C $$dir; done


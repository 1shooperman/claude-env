IMAGE     := claudenv-dev
WORKDIR   := /code
REPO_ROOT := $(shell pwd)
RUN       := docker run --rm \
               -v "$(REPO_ROOT):$(WORKDIR)" \
               -w "$(WORKDIR)" \
               $(IMAGE)

.DEFAULT_GOAL := help

.PHONY: help build lint test check clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	    awk 'BEGIN {FS = ":.*?## "}; {printf "  %-8s %s\n", $$1, $$2}'

# Rebuild the image only when Dockerfile.dev changes.
.docker-image: Dockerfile.dev
	docker build -f Dockerfile.dev -t $(IMAGE) .
	@touch .docker-image

build: .docker-image ## Build (or rebuild) the dev container image

lint: .docker-image ## Lint install.sh (sh) and claudenv.sh (bash) with ShellCheck
	$(RUN) shellcheck --shell=sh   install.sh
	$(RUN) shellcheck --shell=bash claudenv.sh

test: .docker-image ## Run the bats test suite
	$(RUN) bats test/

check: lint test ## Run lint then test — mirrors CI

clean: ## Remove the dev image and build sentinel
	docker rmi $(IMAGE) 2>/dev/null || true
	rm -f .docker-image

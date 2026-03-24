IMAGE_NAME_PREFIX = wsl-mirror-test
SCRIPT_NAME = wsl-mirror.sh
SHELLCHECK_IMG = koalaman/shellcheck:stable

OS_VARIANTS = ubuntu debian
UBUNTU_IMAGE = ubuntu:24.04
DEBIAN_IMAGE = debian:trixie-slim

TEST_LOG = \033[0;34m[Test]\033[0m

.PHONY: all lint build test clean $(OS_VARIANTS)

all: lint build test
build: build-ubuntu build-debian
test: test-ubuntu test-debian

ubuntu: lint build-ubuntu test-ubuntu
debian: lint build-debian test-debian

lint:
	@echo "$(TEST_LOG) Running ShellCheck"
	docker run --rm -v "$(PWD)/..:/mnt" $(SHELLCHECK_IMG) /mnt/$(SCRIPT_NAME)

# --- Ubuntu specific ---
build-ubuntu:
	@echo "$(TEST_LOG) Building Ubuntu image"
	docker build --build-arg BASE_IMAGE=$(UBUNTU_IMAGE) -t $(IMAGE_NAME_PREFIX)-ubuntu -f Dockerfile ..

test-ubuntu:
	@echo "$(TEST_LOG) Testing Ubuntu"
	docker run --rm $(IMAGE_NAME_PREFIX)-ubuntu pytest -v test.py --color=yes

# --- Debian specific ---
build-debian:
	@echo "$(TEST_LOG) Building Debian image"
	docker build --build-arg BASE_IMAGE=$(DEBIAN_IMAGE) -t $(IMAGE_NAME_PREFIX)-debian -f Dockerfile ..

test-debian:
	@echo "$(TEST_LOG) Testing Debian"
	docker run --rm $(IMAGE_NAME_PREFIX)-debian pytest -v test.py --color=yes

clean:
	@echo "$(TEST_LOG) Cleaning up"
	docker rmi $(IMAGE_NAME_PREFIX)-ubuntu $(IMAGE_NAME_PREFIX)-debian || true

IMAGE_NAME_PREFIX = wsl-mirror-test
SCRIPT_NAME = wsl-mirror.sh
SHELLCHECK_IMG = koalaman/shellcheck:stable

OS_VARIANTS = ubuntu24 ubuntu26 debian
UBUNTU24_IMAGE = ubuntu:24.04
UBUNTU26_IMAGE = ubuntu:26.04
DEBIAN_IMAGE = debian:trixie-slim

TEST_LOG = \033[0;34m[Test]\033[0m

.PHONY: all lint build test clean $(OS_VARIANTS)

all: lint build test
build: build-ubuntu24 build-ubuntu26 build-debian
test: test-ubuntu24 test-ubuntu26 test-debian

ubuntu24: lint build-ubuntu24 test-ubuntu24
ubuntu26: lint build-ubuntu26 test-ubuntu26
debian: lint build-debian test-debian

lint:
	@echo "$(TEST_LOG) Running ShellCheck"
	docker run --rm -v "$(PWD)/..:/mnt" $(SHELLCHECK_IMG) /mnt/$(SCRIPT_NAME)

# --- Ubuntu 24.04 ---
build-ubuntu24:
	@echo "$(TEST_LOG) Building Ubuntu 24.04 image"
	docker build --build-arg BASE_IMAGE=$(UBUNTU24_IMAGE) -t $(IMAGE_NAME_PREFIX)-ubuntu24 -f Dockerfile ..

test-ubuntu24:
	@echo "$(TEST_LOG) Testing Ubuntu 24.04"
	docker run --rm $(IMAGE_NAME_PREFIX)-ubuntu24 pytest -v test.py --color=yes

# --- Ubuntu 26.04 ---
build-ubuntu26:
	@echo "$(TEST_LOG) Building Ubuntu 26.04 image"
	docker build --build-arg BASE_IMAGE=$(UBUNTU26_IMAGE) -t $(IMAGE_NAME_PREFIX)-ubuntu26 -f Dockerfile ..

test-ubuntu26:
	@echo "$(TEST_LOG) Testing Ubuntu 26.04"
	docker run --rm $(IMAGE_NAME_PREFIX)-ubuntu26 pytest -v test.py --color=yes

# --- Debian ---
build-debian:
	@echo "$(TEST_LOG) Building Debian image"
	docker build --build-arg BASE_IMAGE=$(DEBIAN_IMAGE) -t $(IMAGE_NAME_PREFIX)-debian -f Dockerfile ..

test-debian:
	@echo "$(TEST_LOG) Testing Debian"
	docker run --rm $(IMAGE_NAME_PREFIX)-debian pytest -v test.py --color=yes

clean:
	@echo "$(TEST_LOG) Cleaning up"
	docker rmi $(IMAGE_NAME_PREFIX)-ubuntu24 $(IMAGE_NAME_PREFIX)-ubuntu26 $(IMAGE_NAME_PREFIX)-debian || true

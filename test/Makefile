# Variables
IMAGE_NAME = wsl-mirror-test
SCRIPT_NAME = wsl-mirror.sh
SHELLCHECK_IMG = koalaman/shellcheck:stable

TEST_LOG = \033[0;34m[Test]\033[0m

.PHONY: all lint build test clean

# Default: Lint, then Build, then Test
all: lint build test

# 1. Run ShellCheck using Docker
# -v mounts the current dir to /mnt in the container
lint:
	@echo "$(TEST_LOG) Running ShellCheck via Docker"
	docker run --rm -v "$(PWD)/..:/mnt" $(SHELLCHECK_IMG) /mnt/$(SCRIPT_NAME)

# 2. Build the Ubuntu 24.04 test environment
build:
	@echo "$(TEST_LOG) Building Docker image"
	docker build -t $(IMAGE_NAME) -f Dockerfile ..

# 3. Run the Python test suite inside the container
test:
	@echo "$(TEST_LOG) Running Pytest"
	docker run --rm $(IMAGE_NAME) pytest -v test.py --color=yes --capture=tee-sys

clean:
	@echo "$(TEST_LOG) Cleaning up"
	docker rmi $(IMAGE_NAME)

debug-container:
	docker run -it --rm $(IMAGE_NAME) bash
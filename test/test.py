import subprocess
import os
import pytest
import platform
from pathlib import Path

TSINGHUA_URL = "mirrors.tuna.tsinghua.edu.cn"
SCRIPT_PATH = "./wsl-mirror.sh"


def get_os_id():
    try:
        # Returns a dictionary of /etc/os-release keys
        info = platform.freedesktop_os_release()
        return info.get("ID")  # should return 'ubuntu' or 'debian'
    except OSError:
        return "unknown"


def run_command(cmd):
    is_shell = isinstance(cmd, str)
    result = subprocess.run(cmd, shell=is_shell, capture_output=True, text=True)
    return result


def call_bash_function(func_name, args=None):
    args_str = " ".join(args) if args else ""
    # We source the script then immediately call the function
    cmd = f"source {SCRIPT_PATH} && {func_name} {args_str}"
    return run_command(["bash", "-c", cmd])


def run_script(args=None):
    cmd = ["bash", SCRIPT_PATH]
    if args:
        cmd.extend(args)
    return run_command(cmd)


class Verifier:
    @staticmethod
    def verify_setup_apt_mirrors():
        OS_URLS = {"ubuntu": "archive.ubuntu.com", "debian": "deb.debian.org"}

        os_id = get_os_id()
        assert os_id in OS_URLS
        ORIGINAL_URL = OS_URLS[os_id]
        SOURCE_PATH = f"/etc/apt/sources.list.d/{os_id}.sources"
        BAK_PATH = f"{SOURCE_PATH}.bak"

        assert os.path.exists(SOURCE_PATH)
        assert os.path.exists(BAK_PATH)
        with open(SOURCE_PATH, "r") as f:
            assert TSINGHUA_URL in f.read()
        with open(BAK_PATH, "r") as f:
            assert ORIGINAL_URL in f.read()
            assert TSINGHUA_URL not in f.read()

    @staticmethod
    def verify_setup_python_pip():
        result = run_command("command -v pip3")
        assert result.returncode == 0
        result = run_command("python3 -m venv -h")
        assert result.returncode == 0
        result = run_command("pip3 config get global.index-url")
        assert TSINGHUA_URL in result.stdout

    @staticmethod
    def verify_setup_node_nvm_and_npm_registry():
        result = run_command("command -v curl")
        assert result.returncode == 0

        assert (Path.home() / ".nvm").is_dir()

        bashrc_path = Path.home() / ".bashrc"
        content = bashrc_path.read_text()
        assert "NVM_DIR" in content
        assert "npmmirror.com" in content

        # use bash -i to load ~/.bashrc
        result = run_command("bash -i -c 'echo $NVM_NODEJS_ORG_MIRROR'")
        assert "npmmirror.com" in result.stdout

        result = run_command("bash -i -c 'node -v'")
        assert result.returncode == 0
        assert "v" in result.stdout

        cmd = "nvm version lts/* && node -v"
        result = run_command(f"bash -i -c '{cmd}'")
        versions = result.stdout.strip().split("\n")
        assert versions[0] == versions[1]

        NPMMIRROR_REGISTRY = "registry.npmmirror.com"
        result = run_command("bash -i -c 'npm config get registry'")
        assert NPMMIRROR_REGISTRY in result.stdout

    @staticmethod
    def verify_set_cuda():
        target_link = Path("/usr/local/cuda/lib64/libcuda.so")
        # Check if the symlink exists
        assert target_link.is_symlink()
        # Check if the symlink points to the correct source
        assert str(target_link.resolve()) == "/usr/lib/wsl/lib/libcuda.so.1"


class TestFullWorkflow:
    def test_script_success(self):
        result = run_script(["-c"])
        assert result.returncode == 0
        assert "Setup Complete" in result.stdout

        Verifier.verify_setup_apt_mirrors()
        Verifier.verify_setup_python_pip()
        Verifier.verify_setup_node_nvm_and_npm_registry()
        Verifier.verify_set_cuda()


class TestIndividualFunctions:
    TEST_DATA = [
        ("setup_apt_mirrors", Verifier.verify_setup_apt_mirrors),
        ("update_and_upgrade", None),
        ("setup_python_pip", Verifier.verify_setup_python_pip),
        (
            "setup_node_nvm_and_npm_registry",
            Verifier.verify_setup_node_nvm_and_npm_registry,
        ),
        ("set_cuda", Verifier.verify_set_cuda),
    ]

    @pytest.mark.parametrize("func_name, verifier", TEST_DATA)
    def test_functions(self, func_name, verifier):
        result = call_bash_function(func_name)
        assert result.returncode == 0

        if verifier is not None:
            verifier()

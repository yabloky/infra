#!/bin/sh

NZ_BASE_PATH="/opt/nezha"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

err() {
    printf "${red}%s${plain}\n" "$*" >&2
}

success() {
    printf "${green}%s${plain}\n" "$*"
}

info() {
    printf "${yellow}%s${plain}\n" "$*"
}

sudo() {
    myEUID=$(id -ru)
    if [ "$myEUID" -ne 0 ]; then
        if command -v sudo > /dev/null 2>&1; then
            command sudo "$@"
        else
            err "ERROR: sudo is not installed"
            exit 1
        fi
    else
        "$@"
    fi
}

deps_check() {
    for dep in curl unzip grep; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            err "Missing dependency: $dep"
            exit 1
        fi
    done
}

env_check() {
    mach=$(uname -m)
    case "$mach" in
        amd64|x86_64)   os_arch="amd64" ;;
        i386|i686)      os_arch="386" ;;
        aarch64|arm64)  os_arch="arm64" ;;
        *arm*)          os_arch="arm" ;;
        s390x)          os_arch="s390x" ;;
        riscv64)        os_arch="riscv64" ;;
        mips)           os_arch="mips" ;;
        mipsel|mipsle)  os_arch="mipsle" ;;
        *)              err "Unknown architecture: $mach"; exit 1 ;;
    esac

    system=$(uname)
    case "$system" in
        *Linux*)    os="linux" ;;
        *Darwin*)   os="darwin" ;;
        *FreeBSD*)  os="freebsd" ;;
        *)          err "Unsupported OS: $system"; exit 1 ;;
    esac
}

install() {
    deps_check
    env_check

    # Твой источник — всегда
    NZ_AGENT_URL="https://raw.githubusercontent.com/yabloky/infra/main/nezha/nezha-agent/nezha-agent_${os}_${os_arch}-latest.zip"

    info "Downloading agent from your backup..."
    if ! curl --max-time 60 -fsSL "$NZ_AGENT_URL" -o "/tmp/nezha-agent.zip"; then
        err "Failed to download agent from your repo"
        exit 1
    fi

    sudo mkdir -p "$NZ_AGENT_PATH"
    sudo unzip -qo "/tmp/nezha-agent.zip" -d "$NZ_AGENT_PATH"
    sudo rm -f "/tmp/nezha-agent.zip"
    sudo chmod +x "$NZ_AGENT_PATH/nezha-agent"

    path="$NZ_AGENT_PATH/config.yml"
    if [ -f "$path" ]; then
        random=$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 5)
        path="$NZ_AGENT_PATH/config-$random.yml"
    fi

    if [ -z "$NZ_SERVER" ]; then
        err "NZ_SERVER is required"
        exit 1
    fi

    if [ -z "$NZ_CLIENT_SECRET" ]; then
        err "NZ_CLIENT_SECRET is required"
        exit 1
    fi

    env="NZ_UUID=$NZ_UUID NZ_SERVER=$NZ_SERVER NZ_CLIENT_SECRET=$NZ_CLIENT_SECRET NZ_TLS=$NZ_TLS NZ_DISABLE_AUTO_UPDATE=$NZ_DISABLE_AUTO_UPDATE NZ_DISABLE_FORCE_UPDATE=$NZ_DISABLE_FORCE_UPDATE NZ_DISABLE_COMMAND_EXECUTE=$NZ_DISABLE_COMMAND_EXECUTE NZ_SKIP_CONNECTION_COUNT=$NZ_SKIP_CONNECTION_COUNT"

    sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$path" uninstall >/dev/null 2>&1
    if sudo env $env "$NZ_AGENT_PATH/nezha-agent" service -c "$path" install; then
        success "nezha-agent successfully installed from your backup"
    else
        err "Failed to install service"
        exit 1
    fi
}

uninstall() {
    find "$NZ_AGENT_PATH" -name "*config*.yml" | while read -r file; do
        sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$file" uninstall
        sudo rm -f "$file"
    done
    info "Uninstallation completed"
}

if [ "$1" = "uninstall" ]; then
    uninstall
    exit 0
fi

install

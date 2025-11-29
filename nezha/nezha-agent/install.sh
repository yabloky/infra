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
    for dep in curl unzip; do
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
        aarch64|arm64)  os_arch="arm64" ;;
        *)              err "Unsupported architecture: $mach"; exit 1 ;;
    esac
    os="linux"
}

install() {
    deps_check
    env_check

    ASSET="nezha-agent_${os}_${os_arch}.zip"
    URL="https://github.com/yabloky/infra/releases/download/nezha-agent-latest/${ASSET}"

    info "Downloading agent from your mirror..."
    curl -L --fail --silent "$URL" -o /tmp/agent.zip || { err "Download failed"; exit 1; }

    sudo mkdir -p "$NZ_AGENT_PATH"
    sudo unzip -qo /tmp/agent.zip -d "$NZ_AGENT_PATH"
    sudo rm -f /tmp/agent.zip
    sudo chmod +x "$NZ_AGENT_PATH/nezha-agent"

    CFG="$NZ_AGENT_PATH/config.yml"
    [ -f "$CFG" ] && CFG="$NZ_AGENT_PATH/config.$(LC_ALL=C tr -dc a-z0-9 </dev/urandom | head -c 6).yml"

    [ -z "$NZ_SERVER" ] && { err "NZ_SERVER is required"; exit 1; }
    [ -z "$NZ_CLIENT_SECRET" ] && { err "NZ_CLIENT_SECRET is required"; exit 1; }

    env="NZ_UUID=$NZ_UUID NZ_SERVER=$NZ_SERVER NZ_CLIENT_SECRET=$NZ_CLIENT_SECRET NZ_TLS=$NZ_TLS NZ_DISABLE_AUTO_UPDATE=$NZ_DISABLE_AUTO_UPDATE NZ_DISABLE_FORCE_UPDATE=$NZ_DISABLE_FORCE_UPDATE NZ_DISABLE_COMMAND_EXECUTE=$NZ_DISABLE_COMMAND_EXECUTE NZ_SKIP_CONNECTION_COUNT=$NZ_SKIP_CONNECTION_COUNT"

    sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$CFG" uninstall >/dev/null 2>&1
    if sudo env $env "$NZ_AGENT_PATH/nezha-agent" service -c "$CFG" install; then
        success "Agent installed from your mirror (nezha-agent-latest)"
    else
        err "Service install failed"
        exit 1
    fi
}

uninstall() {
    find "$NZ_AGENT_PATH" -name "config*.yml" | while read -r f; do
        sudo "$NZ_AGENT_PATH/nezha-agent" service -c "$f" uninstall
        sudo rm -f "$f"
    done
    info "Uninstalled"
}

[ "$1" = "uninstall" ] && { uninstall; exit 0; }

install

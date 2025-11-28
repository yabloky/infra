Как использовать

curl -L https://raw.githubusercontent.com/yabloky/infra/main/nezha/nezha-agent/install.sh -o agent.sh
chmod +x agent.sh
./agent.sh

Или (как в дашборде Nezha):

curl -L https://raw.githubusercontent.com/yabloky/infra/main/nezha/nezha-agent/install.sh -o agent.sh && \
chmod +x agent.sh && \
env NZ_SERVER=your.domain:8008 NZ_CLIENT_SECRET=secret ./agent.sh

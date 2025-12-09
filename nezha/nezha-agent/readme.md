curl -L https://raw.githubusercontent.com/yabloky/infra/main/nezha/nezha-agent/install.sh -o agent.sh && \
chmod +x agent.sh && \
env NZ_SERVER=dashboard.example.com:8008 NZ_TLS=false NZ_CLIENT_SECRET=EXAMPLE NZ_UUID=your_server_uuid ./agent.sh

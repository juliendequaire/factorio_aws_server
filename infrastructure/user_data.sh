#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y wget xz-utils

# Create factorio user
useradd -m -s /bin/bash factorio

# Download and install Factorio
cd /opt
wget -O factorio_headless_x64_1.1.109.tar.xz https://factorio.com/get-download/1.1.109/headless/linux64
tar -xf factorio_headless_x64_1.1.109.tar.xz
chown -R factorio:factorio factorio
rm factorio_headless_x64_1.1.109.tar.xz

# Create systemd service
cat > /etc/systemd/system/factorio.service << 'EOF'
[Unit]
Description=Factorio headless server
Documentation=https://wiki.factorio.com/Multiplayer
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=factorio
Group=factorio
ExecStart=/opt/factorio/bin/x64/factorio --start-server-load-latest --server-settings /opt/factorio/data/server-settings.json
Restart=on-failure
RestartSec=5
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

# Create server settings
mkdir -p /opt/factorio/data
cat > /opt/factorio/data/server-settings.json << 'EOF'
{
  "name": "Factorio Server",
  "description": "Factorio server hosted on AWS",
  "tags": ["game", "tags"],
  "max_players": 10,
  "visibility": {
    "public": false,
    "lan": false
  },
  "username": "",
  "token": "",
  "game_password": "",
  "require_user_verification": true,
  "max_upload_in_kilobytes_per_second": 0,
  "max_upload_slots": 5,
  "minimum_latency_in_ticks": 0,
  "ignore_player_limit_for_returning_players": false,
  "allow_commands": "admins-only",
  "autosave_interval": 10,
  "autosave_slots": 5,
  "afk_autokick_interval": 0,
  "auto_pause": true,
  "only_admins_can_pause_the_game": true,
  "autosave_only_on_server": true,
  "non_blocking_saving": false
}
EOF

chown -R factorio:factorio /opt/factorio

# Enable but don't start the service (will be started via Lambda)
systemctl enable factorio
systemctl daemon-reload

# Create initial save file
sudo -u factorio /opt/factorio/bin/x64/factorio --create /opt/factorio/saves/default.zip
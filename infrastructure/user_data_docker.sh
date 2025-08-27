#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create factorio user and add to docker group
useradd -m -s /bin/bash factorio
usermod -aG docker factorio

# Create application directory
mkdir -p /opt/factorio-docker
cd /opt/factorio-docker

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash factorio

ENV FACTORIO_VERSION=1.1.109

WORKDIR /opt
RUN wget -O factorio_headless_x64_${FACTORIO_VERSION}.tar.xz \
    https://factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64 && \
    tar -xf factorio_headless_x64_${FACTORIO_VERSION}.tar.xz && \
    chown -R factorio:factorio factorio && \
    rm factorio_headless_x64_${FACTORIO_VERSION}.tar.xz

RUN mkdir -p /opt/factorio/saves /opt/factorio/mods /opt/factorio/config

COPY server-settings.json /opt/factorio/data/server-settings.json
RUN chown -R factorio:factorio /opt/factorio

USER factorio
WORKDIR /opt/factorio

RUN ./bin/x64/factorio --create saves/default.zip

EXPOSE 34197/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep factorio || exit 1

CMD ["./bin/x64/factorio", "--start-server-load-latest", "--server-settings", "/opt/factorio/data/server-settings.json"]
EOF

# Create server settings
cat > server-settings.json << 'EOF'
{
  "name": "AWS Factorio Docker Server",
  "description": "Factorio server running in Docker on AWS EC2",
  "tags": ["aws", "docker", "ec2"],
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

# Create docker-compose file
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  factorio:
    build: .
    container_name: factorio-server
    ports:
      - "34197:34197/udp"
    volumes:
      - factorio_saves:/opt/factorio/saves
      - factorio_mods:/opt/factorio/mods
      - factorio_config:/opt/factorio/config
    restart: unless-stopped
    mem_limit: 1.5g
    memswap_limit: 1.5g

volumes:
  factorio_saves:
    driver: local
  factorio_mods:
    driver: local
  factorio_config:
    driver: local
EOF

# Build the Docker image
echo "Building Factorio Docker image..."
docker build -t factorio-server .

# Create systemd service for Docker Compose
cat > /etc/systemd/system/factorio-docker.service << 'EOF'
[Unit]
Description=Factorio Docker Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/factorio-docker
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Set ownership
chown -R factorio:factorio /opt/factorio-docker

# Enable but don't start the service (will be controlled by Lambda)
systemctl daemon-reload
systemctl enable factorio-docker

# Create management scripts
cat > /opt/factorio-docker/start.sh << 'EOF'
#!/bin/bash
cd /opt/factorio-docker
docker compose up -d
EOF

cat > /opt/factorio-docker/stop.sh << 'EOF'
#!/bin/bash
cd /opt/factorio-docker
docker compose down
EOF

cat > /opt/factorio-docker/status.sh << 'EOF'
#!/bin/bash
cd /opt/factorio-docker
docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
EOF

chmod +x /opt/factorio-docker/*.sh

echo "Factorio Docker setup completed successfully!"
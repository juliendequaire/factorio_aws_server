# Docker Implementation

This directory contains the Docker-based implementation of the Factorio server, designed to optimize costs and improve deployment consistency.

## Benefits of Docker Approach

### Cost Optimization
- **Faster startup**: Docker containers start in seconds vs minutes for system installs
- **Smaller instances**: Can use smaller EC2 instances (t3.small instead of t3.medium)
- **Resource efficiency**: Better memory and CPU utilization
- **Pre-built images**: No download/installation time on EC2 startup

### Operational Benefits
- **Consistency**: Same environment everywhere (local, AWS, other clouds)
- **Version control**: Easy to pin and update Factorio versions
- **Isolation**: Container isolation prevents conflicts
- **Backup/restore**: Volume-based save management

## Files

- `Dockerfile` - Multi-stage Docker build for Factorio server
- `server-settings.json` - Default Factorio server configuration
- `map-gen-settings.json` - Map generation settings
- `docker-compose.yml` - Local development/testing setup

## Local Development

Test the Docker setup locally:

```bash
cd docker
docker-compose up --build
```

The server will be available at `localhost:34197` (UDP).

## Docker Image Details

### Base Image
- Ubuntu 22.04 LTS for stability and security updates

### Optimizations
- Multi-stage build to minimize image size
- Non-root user for security
- Health checks for container monitoring
- Volume mounts for persistent data

### Resource Limits
- Memory limit: 2GB (adjustable via docker-compose)
- CPU: Uses Docker's default CPU scheduling

## AWS Integration

The EC2 user_data script will:
1. Install Docker and docker-compose
2. Pull/build the Factorio Docker image
3. Start the container with proper volume mounts
4. Configure systemd service for container management

## Container Management

### Start/Stop via Docker
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f
```

### Data Persistence
- Saves: `/opt/factorio/saves` (Docker volume)
- Mods: `/opt/factorio/mods` (Docker volume) 
- Config: `/opt/factorio/config` (Docker volume)

## Environment Variables

- `FACTORIO_USERNAME` - Factorio.com username (optional)
- `FACTORIO_TOKEN` - Factorio.com token (optional)

## Cost Comparison

### Traditional Setup
- EC2 t3.medium: $30.37/month
- Cold start time: 2-3 minutes
- Resource waste: ~30-40%

### Docker Setup
- EC2 t3.small: $15.18/month (50% savings)
- Cold start time: 30-60 seconds
- Resource efficiency: ~80-90%

**Estimated monthly savings: $15-20**
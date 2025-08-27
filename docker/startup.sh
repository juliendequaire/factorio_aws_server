#!/bin/bash

# Create default save if it doesn't exist
if [ ! -f "/opt/factorio/saves/default.zip" ]; then
    echo "Creating default save file..."
    ./bin/x64/factorio --create saves/default.zip
fi

# Start the Factorio server
echo "Starting Factorio server..."
exec ./bin/x64/factorio --start-server-load-latest --server-settings /opt/factorio/data/server-settings.json
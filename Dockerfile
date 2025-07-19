# Stage 1: Build dependencies and plugin
FROM kong/kong-gateway:3.11-ubuntu AS builder

# Use default kong user (UID 1000) instead of root
USER kong
WORKDIR /app
COPY --chown=kong:kong . /app

# Install dependencies using kong user
RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends luarocks && \
    sudo rm -rf /var/lib/apt/lists/*

# Install plugin dependencies
RUN luarocks install lua-resty-openidc

# Stage 2: Prepare plugin bundle
FROM kong/kong-gateway:3.11-ubuntu AS packager

# Use kong user
USER kong
WORKDIR /home/kong

# Copy from builder stage to a writable location
COPY --from=builder --chown=kong:kong /app/kong/plugins/oidc/ ./plugin_build_area/kong/plugins/oidc/
COPY --from=builder --chown=kong:kong /usr/local/share/lua/5.1/ ./plugin_build_area/lua/5.1/

# Create tarball in home directory
RUN tar -czf plugin.tar.gz -C plugin_build_area .

# Stage 3: Final output
FROM scratch
COPY --from=packager /home/kong/plugin.tar.gz /
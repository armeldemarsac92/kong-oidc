# Stage 1: Build dependencies and plugin
FROM kong/kong-gateway:3.11-ubuntu AS builder

USER root
RUN apt-get update && apt-get install -y --no-install-recommends luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN luarocks install lua-resty-openidc

# Stage 2: Prepare plugin bundle
FROM kong/kong-gateway:3.11-ubuntu AS packager

# Copy from builder stage
COPY --from=builder /app/kong/plugins/oidc/ /plugin_build_area/kong/plugins/oidc/
COPY --from=builder /usr/local/share/lua/5.1/ /plugin_build_area/lua/5.1/

# Create tarball
RUN tar -czf /plugin.tar.gz -C /plugin_build_area .

# Stage 3: Final output
FROM scratch
COPY --from=packager /plugin.tar.gz /
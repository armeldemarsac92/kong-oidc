# Stage 1: Builder
# Use the official Kong Gateway image as a builder to get necessary tools (luarocks)
FROM kong/kong-gateway:3.11-ubuntu AS builder

USER root
# Update apt and install luarocks (git is no longer needed for cloning this repo)
RUN apt-get update && apt-get install -y --no-install-recommends luarocks \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated directory for all plugin components that will be bundled
# This will be the root for our plugin's collected files before tarring
WORKDIR /plugin_build_area

# Copy the OIDC plugin's files directly from the build context (where this Dockerfile resides)
# into the /plugin_build_area. This avoids the circular dependency.
COPY ./kong/plugins/oidc/ /plugin_build_area/kong/plugins/oidc/

# Install lua-resty-openidc. By default, luarocks installs into /usr/local/share/lua/5.1/
# We will then copy these installed files into our /plugin_build_area.
RUN luarocks install lua-resty-openidc

# Copy the Lua dependencies installed by luarocks from their default location
# into the /plugin_build_area. This ensures all necessary runtime files are bundled.
COPY --from=builder /usr/local/share/lua/5.1/ /plugin_build_area/lua/5.1/
# If there are C-based Lua modules (.so files) for dependencies, copy them too
# COPY --from=builder /usr/local/lib/lua/5.1/ /plugin_build_area/lib/lua/5.1/

# Now, create a single tarball of all the collected plugin files and dependencies
# The -C /plugin_build_area ensures the tarball contents are relative to this directory
RUN tar -czf /plugin.tar.gz -C /plugin_build_area .

# Stage 2: Final Image (minimal 'scratch' image)
FROM scratch

# Copy the single tarball from the builder stage to the root of the scratch image
COPY --from=builder /plugin.tar.gz /

# The ENTRYPOINT is not strictly necessary for KongPluginInstallation images,
# as the operator extracts the tarball.
# ENTRYPOINT ["/bin/true"]

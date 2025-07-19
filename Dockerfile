FROM kong/kong-gateway:3.11-ubuntu AS builder

USER root
RUN apt-get update && apt-get install -y --no-install-recommends luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN luarocks install lua-resty-openidc

WORKDIR /plugin_build_area

COPY --from=builder /app/kong/plugins/oidc/ /plugin_build_area/kong/plugins/oidc/

COPY --from=builder /usr/local/share/lua/5.1/ /plugin_build_area/lua/5.1/

RUN tar -czf /plugin.tar.gz -C /plugin_build_area .

FROM scratch

COPY --from=builder /plugin.tar.gz /


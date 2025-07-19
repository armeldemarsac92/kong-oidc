FROM kong/kong-gateway:3.11-ubuntu AS builder

USER root
RUN apt-get update && apt-get install -y --no-install-recommends luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /plugin_build_area

RUN luarocks install lua-resty-openidc

COPY ./kong/plugins/oidc/ ./kong/plugins/oidc/

COPY --from=builder /usr/local/share/lua/5.1/ /plugin_build_area/lua/5.1/

RUN tar -czf /plugin.tar.gz -C /plugin_build_area .

FROM scratch

COPY --from=builder /plugin.tar.gz /


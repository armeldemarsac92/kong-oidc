FROM kong/kong-gateway:3.11-ubuntu AS builder

USER root
RUN apt-get update && apt-get install -y --no-install-recommends luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN luarocks install lua-resty-openidc

WORKDIR /plugin-bundle

COPY ./kong/plugins/oidc/ ./kong/plugins/oidc/

COPY --from=builder /usr/local/share/lua/5.1/ ./lua/5.1/

RUN tar -czf /plugin.tar.gz -C /plugin-bundle .

FROM scratch

COPY --from=builder /plugin.tar.gz /


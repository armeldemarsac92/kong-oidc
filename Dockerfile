FROM kong/kong-gateway:3.11 AS builder
USER root
RUN apt-get update && apt-get install -y --no-install-recommends git luarocks \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone https://github.com/armeldemarsac92/kong-oidc.git
RUN luarocks install lua-resty-openidc

RUN git clone https://github.com/armeldemarsac92/kong-plugin-jwt-keycloak.git

FROM scratch

COPY --from=builder /tmp/kong-oidc/kong/plugins/oidc/ /kong/plugins/oidc/

COPY --from=builder /usr/local/share/lua/5.1/ /usr/local/share/lua/5.1/
COPY --from=builder /usr/local/lib/lua/5.1/ /usr/local/lib/lua/5.1/

COPY --from=builder /tmp/kong-plugin-jwt-keycloak/src/ /kong/plugins/jwt-keycloak/
COPY --from=builder /tmp/kong-plugin-jwt-keycloak/src/validators /kong/plugins/jwt-keycloak/validators

ENTRYPOINT ["/bin/true"]
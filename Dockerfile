FROM kong/kong:3.9.1-ubuntu

USER root

RUN apt update && apt install -y git luarocks

# === Clone OIDC plugin ===
WORKDIR /tmp
RUN git clone https://github.com/armeldemarsac92/kong-oidc.git

RUN luarocks install lua-resty-openidc

# Copier le plugin OIDC
RUN mkdir -p /usr/local/share/lua/5.1/kong/plugins/oidc \
    && cp /tmp/kong-oidc/kong/plugins/oidc/*.lua /usr/local/share/lua/5.1/kong/plugins/oidc/

# === Clone JWT Keycloak plugin ===
WORKDIR /tmp
RUN git clone --branch master https://github.com/armeldemarsac92/kong-plugin-jwt-keycloak.git

# Copier les fichiers Lua et le dossier validators dans l’arborescence attendue
RUN mkdir -p /usr/local/share/lua/5.1/kong/plugins/jwt-keycloak \
    && cp /tmp/kong-plugin-jwt-keycloak/src/*.lua /usr/local/share/lua/5.1/kong/plugins/jwt-keycloak/ \
    && cp -r /tmp/kong-plugin-jwt-keycloak/src/validators /usr/local/share/lua/5.1/kong/plugins/jwt-keycloak/

# Activer les plugins
ENV KONG_PLUGINS=bundled,oidc,jwt-keycloak

USER kong

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 8000 8443 8001 8444
STOPSIGNAL SIGQUIT
HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health
CMD ["kong", "docker-start"]

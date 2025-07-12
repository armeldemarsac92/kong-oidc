-- kong/plugins/otter-auth/handler.lua

local oidc = require("resty.openidc")
local jwt_validators = require("resty.jwt-validators")
local utils = require("kong.plugins.oidc.utils")
local filter = require("kong.plugins.oidc.filter")
local session = require("kong.plugins.oidc.session")

local plugin = {
  VERSION = "1.3.0",
  PRIORITY = 1000,
}

-- Injecte les credentials, groupes et headers
local function inject_all(entity, conf)
  utils.setCredentials(entity)
  utils.injectGroups(entity, conf.groups_claim)
  utils.injectHeaders(conf.header_names, conf.header_claims, { entity })

  if not conf.disable_userinfo_header then
    utils.injectUser(entity, conf.userinfo_header_name)
  end
end

-- Appelle la bibliothèque OIDC pour effectuer l’authentification interactive
local function make_oidc(conf)
  kong.log.debug("Authenticating request via OIDC for path: ", kong.request.get_path())

  local unauth_action = conf.unauth_action == "auth" and "auth" or "deny"
  local res, err = oidc.authenticate(conf, kong.request.get_path(), unauth_action)

  if err then
    if err == "unauthorized request" then
      return kong.response.exit(401, { message = "Unauthorized" })
    elseif conf.recovery_page_path then
      kong.log.debug("Redirecting to recovery page: ", conf.recovery_page_path)
      return kong.response.exit(302, "", { ["Location"] = conf.recovery_page_path })
    else
      kong.log.err("OIDC authentication failed: ", err)
      return kong.response.exit(500, { message = "Internal Server Error" })
    end
  end

  return res
end

-- Vérifie un token JWT signé via JWKS
local function verify_bearer_jwt(conf)
  if not utils.has_bearer_access_token() then
    return nil
  end

  local opts = {
    discovery = conf.discovery,
    timeout = conf.timeout,
    ssl_verify = conf.ssl_verify,
    accept_none_alg = false,
    accept_unsupported_alg = false,
    token_signing_alg_values_expected = conf.bearer_jwt_auth_signing_algs,
  }

  local discovery_doc, err = oidc.get_discovery_doc(opts)
  if err then
    kong.log.err("OIDC discovery failed for Bearer JWT: ", err)
    return nil
  end

  local allowed_auds = conf.bearer_jwt_auth_allowed_auds or conf.client_id

  jwt_validators.set_system_leeway(120)
  local claim_spec = {
    iss = jwt_validators.equals(discovery_doc.issuer),
    sub = jwt_validators.required(),
    aud = function(val) return utils.has_common_item(val, allowed_auds) end,
    exp = jwt_validators.is_not_expired(),
    iat = jwt_validators.required(),
    nbf = jwt_validators.opt_is_not_before(),
  }

  local json, err = oidc.bearer_jwt_verify(opts, claim_spec)
  if err then
    kong.log.err("Bearer JWT verification failed: ", err)
    return nil
  end

  return json
end

local function has_scope(scope_string, expected)
  if not scope_string then return false end
  for scope in scope_string:gmatch("[^%s]+") do
    if scope == expected then return true end
  end
  return false
end

-- Appelle introspection ou JWKS selon configuration
local function introspect(conf)
  if not (utils.has_bearer_access_token() or conf.bearer_only == "yes") then
    return nil
  end

  local res, err
  if conf.use_jwks == "yes" then
    res, err = oidc.bearer_jwt_verify(conf)
  else
    res, err = oidc.introspect(conf)
  end

  if err then
    if conf.bearer_only == "yes" then
      return kong.response.exit(401, {
        message = err,
        headers = {
          ["WWW-Authenticate"] = 'Bearer realm="' .. conf.realm .. '", error="' .. err .. '"'
        }
      })
    end
    return nil
  end

  if conf.validate_scope == "yes" and not has_scope(res.scope, conf.scope) then
    kong.log.err("Scope validation failed for: ", res.scope)
    return kong.response.exit(403, { message = "Forbidden - insufficient scope" })
  end

  kong.log.debug("Token introspection succeeded for path: ", kong.request.get_path())
  return res
end

function plugin.access(conf)
  local oidcConfig = utils.get_options(conf, ngx)

  if oidcConfig.skip_already_auth_requests and kong.client.get_credential() then
    kong.log.debug("Skipping already authenticated request: ", kong.request.get_path())
    return
  end

  if not filter.shouldProcessRequest(oidcConfig) then
    kong.log.debug("Skipping OIDC for path: ", kong.request.get_path())
    return
  end

  session.configure(conf)

  local response

  if oidcConfig.bearer_jwt_auth_enable then
    response = verify_bearer_jwt(oidcConfig)
    if response then
      inject_all(response, oidcConfig)
      return
    end
  end

  if oidcConfig.introspection_endpoint then
    response = introspect(oidcConfig)
    if response then
      inject_all(response, oidcConfig)
      return
    end
  end

  response = make_oidc(oidcConfig)
  if response then
    local principal = response.user or response.id_token
    utils.setCredentials(principal)
    utils.injectGroups(principal, oidcConfig.groups_claim)
    utils.injectHeaders(oidcConfig.header_names, oidcConfig.header_claims, { response.user, response.id_token })

    if not oidcConfig.disable_userinfo_header and response.user then
      utils.injectUser(response.user, oidcConfig.userinfo_header_name)
    end

    if not oidcConfig.disable_access_token_header and response.access_token then
      utils.injectAccessToken(response.access_token, oidcConfig.access_token_header_name, oidcConfig.access_token_as_bearer)
    end

    if not oidcConfig.disable_id_token_header and response.id_token then
      utils.injectIDToken(response.id_token, oidcConfig.id_token_header_name)
    end
  end
end

return plugin

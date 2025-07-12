local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "my-plugin"

return {
  name = PLUGIN_NAME,
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    {
      config = {
        type = "record",
        fields = {
          { client_id = { type = "string", required = true } },
          { client_secret = { type = "string", required = true } },
          { discovery = { type = "string", required = true, default = "https://.well-known/openid-configuration" } },
          { introspection_endpoint = { type = "string" } },
          { introspection_endpoint_auth_method = { type = "string" } },
          { introspection_cache_ignore = { type = "string", required = true, default = "no" } },
          { timeout = { type = "number" } },
          { bearer_only = { type = "string", required = true, default = "no" } },
          { realm = { type = "string", required = true, default = "kong" } },
          { redirect_uri = { type = "string" } },
          { scope = { type = "string", required = true, default = "openid" } },
          { validate_scope = { type = "string", required = true, default = "no" } },
          { response_type = { type = "string", required = true, default = "code" } },
          { ssl_verify = { type = "string", required = true, default = "no" } },
          { use_jwks = { type = "string", required = true, default = "no" } },
          { token_endpoint_auth_method = { type = "string", required = true, default = "client_secret_post" } },
          { session_secret = { type = "string" } },
          { recovery_page_path = { type = "string" } },
          { logout_path = { type = "string", default = "/logout" } },
          { redirect_after_logout_uri = { type = "string", default = "/" } },
          { redirect_after_logout_with_id_token_hint = { type = "string", default = "no" } },
          { post_logout_redirect_uri = { type = "string" } },
          { unauth_action = { type = "string", default = "auth" } },
          { filters = { type = "string" } },
          { ignore_auth_filters = { type = "string" } },
          { userinfo_header_name = { type = "string", default = "X-USERINFO" } },
          { id_token_header_name = { type = "string", default = "X-ID-Token" } },
          { access_token_header_name = { type = "string", default = "X-Access-Token" } },
          { access_token_as_bearer = { type = "string", default = "no" } },
          { disable_userinfo_header = { type = "string", default = "no" } },
          { disable_id_token_header = { type = "string", default = "no" } },
          { disable_access_token_header = { type = "string", default = "no" } },
          { revoke_tokens_on_logout = { type = "string", default = "no" } },
          { groups_claim = { type = "string", default = "groups" } },
          { skip_already_auth_requests = { type = "string", default = "no" } },
          { bearer_jwt_auth_enable = { type = "string", default = "no" } },
          { bearer_jwt_auth_allowed_auds = {
            type = "array",
            elements = { type = "string" }
          }},
          { bearer_jwt_auth_signing_algs = {
            type = "array",
            required = true,
            default = { "RS256" },
            elements = { type = "string" }
          }},
          { header_names = {
            type = "array",
            required = true,
            default = {},
            elements = { type = "string" }
          }},
          { header_claims = {
            type = "array",
            required = true,
            default = {},
            elements = { type = "string" }
          }},
          { http_proxy = { type = "string" } },
          { https_proxy = { type = "string" } }
        }
      }
    }
  }
}

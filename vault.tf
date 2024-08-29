resource "vault_mount" "tenant_mount" {
  path = var.secret-mount
  type = "kv"
  options = {
    version = "2"
  }
}

resource "vault_kv_secret_v2" "tenant_secret" {
  mount = vault_mount.tenant_mount.path
  name  = var.secret-path
  data_json = jsonencode(
    {}
  )

  lifecycle {
    ignore_changes = [
      data_json
    ]
  }
}

resource "vault_policy" "kv-reader" {
  name = "kv-reader"

  policy = <<EOT
path "secret/*" {
    capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "kv-admin" {
  name = "kv-admin"

  policy = <<EOT
path "/secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOT
}

resource "vault_identity_group" "reader-group" {
  name     = "reader-group"
  type     = "external"
  policies = ["kv-reader"]
}

resource "vault_identity_group_alias" "reader-group-alias" {
  name           = azuread_group.reader-group.id
  mount_accessor = vault_jwt_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.reader-group.id
}

resource "vault_identity_group" "admin-group" {
  name     = "admin-group"
  type     = "external"
  policies = ["kv-admin"]
}

resource "vault_identity_group_alias" "admin-group-alias" {
  name           = azuread_group.admin-group.id
  mount_accessor = vault_jwt_auth_backend.oidc.accessor
  canonical_id   = vault_identity_group.admin-group.id
}

resource "vault_jwt_auth_backend" "oidc" {
  path               = "oidc"
  type               = "oidc"
  oidc_discovery_url = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0"
  oidc_client_id     = azuread_service_principal.vault-entra-id.client_id
  oidc_client_secret = azuread_service_principal_password.vault-entra-id.value
  default_role       = "reader"
}

resource "vault_jwt_auth_backend_role" "oidc-reader" {
  backend        = vault_jwt_auth_backend.oidc.path
  role_name      = "reader"
  token_policies = []

  user_claim   = "email"
  groups_claim = "groups"

  bound_claims = {
    groups = azuread_group.reader-group.id
  }

  role_type = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
  ]
  oidc_scopes = ["https://graph.microsoft.com/.default"]
}

resource "vault_jwt_auth_backend_role" "oidc-admin" {
  backend                 = vault_jwt_auth_backend.oidc.path
  role_name               = "admin"
  token_policies          = []
  token_no_default_policy = false
  verbose_oidc_logging    = true

  user_claim   = "email"
  groups_claim = "groups"

  bound_claims = {
    groups = azuread_group.admin-group.id
  }

  role_type = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
  ]
  oidc_scopes = ["https://graph.microsoft.com/.default"]
}
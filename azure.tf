data "azuread_client_config" "current" {}

resource "azuread_application" "vault-entra-id" {
  display_name = "vault-entra-id"
  owners       = [data.azuread_client_config.current.object_id]

  required_resource_access {
    # Microsoft Graph
    # az ad sp list --display-name "Microsoft Graph" --query '[].{appDisplayName:appDisplayName, appId:appId}'
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      # GroupMember.Read.All
      # az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'"
      id   = "bc024368-1153-4739-b217-4326f2e966d0"
      type = "Scope"
    }
  }

  web {
    redirect_uris = [
      "http://localhost:8250/oidc/callback",
      "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
    ]
  }

  group_membership_claims = ["SecurityGroup"]

  optional_claims {
    id_token {
      name                  = "groups"
      additional_properties = []
    }
    id_token {
      name                  = "email"
      additional_properties = []
    }
  }
}

resource "azuread_service_principal" "vault-entra-id" {
  client_id                    = azuread_application.vault-entra-id.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "time_rotating" "example" {
  rotation_days = 7
}

resource "azuread_service_principal_password" "vault-entra-id" {
  service_principal_id = azuread_service_principal.vault-entra-id.id
  rotate_when_changed = {
    rotation = time_rotating.example.id
  }
}

resource "azuread_user" "reader" {
  display_name        = "Test Reader"
  password            = var.entra-user-password
  user_principal_name = "reader@${var.entra-domain}"
  mail                = "reader@${var.entra-domain}"
  mail_nickname       = "reader"
}

resource "azuread_user" "admin" {
  display_name        = "Test Admin"
  password            = var.entra-user-password
  user_principal_name = "admin@${var.entra-domain}"
  mail                = "admin@${var.entra-domain}"
  mail_nickname       = "admin"
}

resource "azuread_user" "noaccess" {
  display_name        = "Test NoAccess"
  password            = var.entra-user-password
  user_principal_name = "noaccess@${var.entra-domain}"
  mail                = "noaccess@${var.entra-domain}"
  mail_nickname       = "noaccess"
}

resource "azuread_group" "noaccess-group" {
  display_name     = "noaccess-group"
  mail_nickname    = "noaccess-group"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    azuread_user.noaccess.object_id,
  ]
}
resource "azuread_group" "reader-group" {
  display_name     = "reader-group"
  mail_nickname    = "reader-group"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    azuread_user.reader.object_id,
    azuread_user.admin.object_id,
  ]
}

resource "azuread_group" "admin-group" {
  display_name     = "admin-group"
  mail_nickname    = "admin-group"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = [
    azuread_user.admin.object_id,
  ]
}
# HashiCorp Vault agent configuration for Raft snapshots
# (Docker variant of vault-snapshot-agent/docs/vm-configuration.md)

vault {
  address = "http://vault:8200"
}

api_proxy {
  # Authenticate all proxied requests with the auto_auth token
  use_auto_auth_token = true
}

listener "tcp" {
  address     = "0.0.0.0:8100"
  tls_disable = true
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path                   = "/etc/vault.d/snap-roleid"
      secret_id_file_path                 = "/etc/vault.d/snap-secretid"
      remove_secret_id_file_after_reading = false
    }
  }
}

exit_after_auth = false
pid_file = "/vault/agent/pidfile"

auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/vault/tokens/root.token"
    }
  }

  sink "file" {
    config = {
      path = "/vault/agent/last_token"
    }
  }
}

template {
  source      = "/vault/templates/banka-ca-key.ctmpl"
  destination = "/vault/rendered/banka/ca-key.pem"
  perms       = "0600"
}

template {
  source      = "/vault/templates/banka-ca-cert.ctmpl"
  destination = "/vault/rendered/banka/ca-cert.pem"
  perms       = "0644"
}

template {
  source      = "/vault/templates/bankb-ca-key.ctmpl"
  destination = "/vault/rendered/bankb/ca-key.pem"
  perms       = "0600"
}

template {
  source      = "/vault/templates/bankb-ca-cert.ctmpl"
  destination = "/vault/rendered/bankb/ca-cert.pem"
  perms       = "0644"
}

template {
  source      = "/vault/templates/consortiumops-ca-key.ctmpl"
  destination = "/vault/rendered/consortiumops/ca-key.pem"
  perms       = "0600"
}

template {
  source      = "/vault/templates/consortiumops-ca-cert.ctmpl"
  destination = "/vault/rendered/consortiumops/ca-cert.pem"
  perms       = "0644"
}

template {
  source      = "/vault/templates/regulatorobserver-ca-key.ctmpl"
  destination = "/vault/rendered/regulatorobserver/ca-key.pem"
  perms       = "0600"
}

template {
  source      = "/vault/templates/regulatorobserver-ca-cert.ctmpl"
  destination = "/vault/rendered/regulatorobserver/ca-cert.pem"
  perms       = "0644"
}

template {
  source      = "/vault/templates/ordererOrg-ca-key.ctmpl"
  destination = "/vault/rendered/ordererOrg/ca-key.pem"
  perms       = "0600"
}

template {
  source      = "/vault/templates/ordererOrg-ca-cert.ctmpl"
  destination = "/vault/rendered/ordererOrg/ca-cert.pem"
  perms       = "0644"
}


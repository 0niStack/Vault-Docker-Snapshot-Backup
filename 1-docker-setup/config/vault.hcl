ui            = true
disable_mlock = true

# Raft integrated storage - this is what `raft snapshot` backs up.
storage "raft" {
  path    = "/vault/file"
  node_id = "node1"
}

# Lab setup: plain HTTP. Use TLS (tls_cert_file/tls_key_file) for production.
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr     = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

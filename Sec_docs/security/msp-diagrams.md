# MSP Trust Topology (ASCII)

## 1. Consortium Trust Tree
```
                          ┌────────────────────────────────────┐
                          │   Consortium Root Trust Anchor     │
                          │   (Vault-rendered root bundle)     │
                          └────────────────────────────────────┘
                                        │
             ┌──────────────────────────┼──────────────────────────┬──────────────────────────┬───────────────────────────────────┐
             │                          │                          │                          │                                   │
┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐  ┌────────────────────────┐    ┌──────────────────────────────────┐
│ OrdererOrg Fabric CA   │  │ BankA Fabric CA        │  │ BankB Fabric CA        │  │ ConsortiumOps Fabric CA│    │  RegulatorObserver Fabric        │
│ ca-orderer (9054)      │  │ ca-banka (7054)        │  │ ca-bankb (8054)        │  │ ca-consortiumops (10054)│   │  ca-regulatorobserver (11054)    │
│ vault/rendered/orderer │  │ vault/rendered/banka   │  │ vault/rendered/bankb   │  │vault/rendered/consortiumops │  vault/rendered/regulatorobserver│
└──────────────┬─────────┘  └──────────────┬─────────┘  └──────────────┬─────────┘  └──────────────────┬─────┘    └──────────────────┬───────────────┘
               │                           │                           │                               │                             │
   ┌───────────┴───────────┐     ┌─────────┴────────────┐      ┌───────┴─────────────┐      ┌──────────┴───────────┐      ┌──────────┴───────────────┐
   │ MSP: OrdererMSP       │     │ MSP: BankAMSP        │      │ MSP: BankBMSP       │      │ MSP: ConsortiumOpsMSP│      │ MSP: RegulatorObserverMSP│
   │ - domain: orderer...  │     │ - domain: banka...   │      │ - domain: bankb...  │      │ - domain: consortium │      │ - domain: regulator...   │
   │ - NodeOUs -> cacerts/ │     │ - NodeOUs -> cacerts/│      │- NodeOUs -> cacerts/│      │ - NodeOUs -> cacerts/│      │ - NodeOUs -> cacerts/    │
   │   localhost-9054-...  │     │   localhost-7054-... │      │   localhost-8054-...│      │   localhost-10054-...│      │   localhost-11054-...    │
   └───────────────────────┘     └──────────┬───────────┘      └──────────┬──────────┘      └──────────┬───────────┘      └──────────┬───────────────┘
                                            │                             │                            │                             │
                              ┌─────────────┴─────────────┐  ┌────────────┴──────────┐   ┌─────────────┴─────────┐   ┌───────────────┴────────┐
                              │ Peers/Admins/Clients      │  │ Peers/Admins/Clients  │   │ Peers/Admins/Clients  │   │ Peer/Admin/Observer    │
                              │ - peer0/peer1 TLS/MSP     │  │ - peer0/peer1 TLS/MSP │   │ - peer0 TLS/MSP       │   │ - peer0 TLS/MSP        │
                              │ - Admin@..., User1@...    │  │ - Admin@..., User1@.. │   │ - Admin@..., Auditor@ │   │ - Admin@..., Auditor@  │
                              │ - Auditor@... (where used)│  │ - Auditor@...         │   │                       │   │                        │
                              └───────────────────────────┘  └───────────────────────┘   └───────────────────────┘   └────────────────────────┘
```

## 2. Certificate Flow per Organization
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Vault Transit Key (banka-ca)                                                 │
│ - Path: vault/rendered/banka/{ca-key.pem, ca-cert.pem}                       │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │ (rendered via vault_agent sidecar)
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Fabric CA Container (ca_banka, port 7054)                                    │
│ - Env: FABRIC_CA_SERVER_CA_KEYFILE=/vault/rendered/banka/ca-key.pem          │
│ - CSR hosts: peer0/peer1/admin/localhost                                     │
│ - Expiry: csr.ca.expiry=720h                                                 │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │ issues
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ BankA Enrollment & TLS Certs                                                 │
│ - peer0/peer1.banka.example.com                                              │
│ - Admin@banka, User1@banka, Auditor@banka                                    │
│ - Stored under organizations/peerOrganizations/banka.example.com/...         │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │ referenced by
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ BankAMSP config.yaml                                                         │
│ - NodeOUs => cacerts/localhost-7054-ca-banka.pem                             │
│ - Enables client/peer/admin/orderer roles                                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

### BankB (BankBMSP)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Vault Transit Key (bankb-ca)                                                 │
│ - Path: vault/rendered/bankb/{ca-key.pem, ca-cert.pem}                       │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Fabric CA (ca_bankb, port 8054)                                              │
│ - FABRIC_CA_SERVER_CA_KEYFILE=/vault/rendered/bankb/ca-key.pem               │
│ - CSR hosts: peer0/peer1/admin/localhost                                     │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ BankB Identities                                                             │
│ - peer0/peer1.bankb.example.com (MSP + TLS)                                  │
│ - Admin@bankb, User1@bankb, Auditor@bankb                                    │
│ - organizations/peerOrganizations/bankb.example.com/...                      │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ BankBMSP config.yaml                                                         │
│ - NodeOUs => cacerts/localhost-8054-ca-bankb.pem                             │
└──────────────────────────────────────────────────────────────────────────────┘
```

### ConsortiumOps (ConsortiumOpsMSP)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Vault Transit Key (consortiumops-ca)                                         │
│ - Path: vault/rendered/consortiumops/{ca-key.pem, ca-cert.pem}               │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Fabric CA (ca_consortiumops, port 10054)                                     │
│ - Hosts: peer0.consortiumops.example.com, admin, localhost                   │
│ - Expiry: 720h                                                               │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ ConsortiumOps Identities                                                     │
│ - peer0.consortiumops.example.com (MSP + TLS)                                │
│ - Admin@consortiumops, User1@..., Auditor@...                                │
│ - organizations/peerOrganizations/consortiumops.example.com/...              │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ ConsortiumOpsMSP config.yaml                                                 │
│ - NodeOUs => cacerts/localhost-10054-ca-consortiumops.pem                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

### RegulatorObserver (RegulatorObserverMSP)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Vault Transit Key (regulatorobserver-ca)                                     │
│ - Path: vault/rendered/regulatorobserver/{ca-key.pem, ca-cert.pem}           │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Fabric CA (ca_regulatorobserver, port 11054)                                 │
│ - Hosts: peer0.regulatorobserver.example.com, auditor, admin, localhost      │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ RegulatorObserver Identities                                                 │
│ - peer0.regulatorobserver.example.com                                        │
│ - Admin@regulatorobserver, User1@..., Auditor@...                            │
│ - organizations/peerOrganizations/regulatorobserver.example.com/...          │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ RegulatorObserverMSP config.yaml                                             │
│ - NodeOUs => cacerts/localhost-11054-ca-regulatorobserver.pem                │
└──────────────────────────────────────────────────────────────────────────────┘
```

### OrdererOrg (OrdererMSP)
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Vault Transit Key (orderer-ca)                                               │
│ - Path: vault/rendered/orderer/{ca-key.pem, ca-cert.pem}                     │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Fabric CA (ca_orderer, port 9054)                                            │
│ - Hosts: orderer.orderer.example.com, admin, localhost                       │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ Orderer Identities                                                           │
│ - orderer.orderer.example.com (MSP + TLS)                                    │
│ - Admin@orderer.example.com                                                  │
│ - organizations/ordererOrganizations/orderer.example.com/...                 │
└──────────────┬───────────────────────────────────────────────────────────────┘
               │
               v
┌──────────────────────────────────────────────────────────────────────────────┐
│ OrdererMSP config.yaml                                                       │
│ - NodeOUs => cacerts/localhost-9054-ca-orderer.pem                           │
└──────────────────────────────────────────────────────────────────────────────┘
```

## 3. Diagram Metadata
- Source: generated from current repo state (`fabric-dev-network/compose/compose-ca.yaml`, `organizations/peerOrganizations/*/msp/config.yaml`, and `orgs.yaml`).
- Update cadence: refresh whenever CA hierarchy, Vault paths, or MSP NodeOU references change.
- Storage: keep ASCII diagrams in version control; export graphical versions to `docs/security/MSP-diagrams/` if/when a GUI tool is used.

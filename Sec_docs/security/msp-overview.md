# MSP Overview – Domains, Roles, Validity, Revocation

```
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| Organization   | Domain / MSP / CA             | NodeOU Roles                         | Certificate Validity                     | Revocation Procedure                                         |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| OrdererOrg     | Domain: orderer.example.com   | Client, Admin, Orderer (peer unused) | CA: csr.ca.expiry=720h (~30 days)        | fabric-ca-client revoke --caname ca-orderer <serial/aki>     |
| (OrdererMSP)   | MSP: OrdererMSP               | NodeOUs -> cacerts/localhost-9054-   | Enrollment/TLS renew via scripts/certs/  | fabric-ca-client gencrl --caname ca-orderer                  |
| CA: ca_orderer | CA Host: ca_orderer:9054      |    ca-orderer.pem                    |    renew_tls.sh (annual target)          | Copy CRL to organizations/ordererOrganizations/.../msp/crls,|
| Vault: vault/  | Vault: rendered/orderer       |                                      |                                           | restart orderer containers                                   |
| rendered/      |                               |                                      |                                           |                                                              |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| BankA          | Domain: banka.example.com     | Client, Peer, Admin, Orderer (future)| CA: 720h                                 | fabric-ca-client revoke --caname ca-banka --revoke.serial ...|
| (BankAMSP)     | MSP: BankAMSP                 | NodeOUs -> cacerts/localhost-7054-   | TLS renew every 90 days; enrollment      | (optionally --revoke.name)                                   |
| CA: ca_banka   | CA Host: ca_banka:7054        |    ca-banka.pem                      | certs every 6 months via renew_tls.sh    | fabric-ca-client gencrl --caname ca-banka; copy CRL to       |
| Vault: vault/  | Vault: rendered/banka         |                                      |                                           | organizations/peerOrganizations/banka.example.com/msp/crls/  |
| rendered/banka |                               |                                      |                                           | restart affected peers/users                                 |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| BankB          | Domain: bankb.example.com     | Client, Peer, Admin, Orderer         | CA: 720h                                 | Same as BankA but using ca-bankb endpoints and paths         |
| (BankBMSP)     | MSP: BankBMSP                 | NodeOUs -> cacerts/localhost-8054-   | TLS 90 days / enrollment 6 months        | Copy CRL under organizations/peerOrganizations/bankb...      |
| CA: ca_bankb   | CA Host: ca_bankb:8054        |    ca-bankb.pem                      |                                           |                                                              |
| Vault: vault/  | Vault: rendered/bankb         |                                      |                                           |                                                              |
| rendered/bankb |                               |                                      |                                           |                                                              |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| ConsortiumOps  | Domain: consortiumops.example.| Client, Peer, Admin, Orderer         | CA: 720h                                 | fabric-ca-client revoke --caname ca-consortiumops ...        |
| (ConsortiumOps | MSP: ConsortiumOpsMSP         | NodeOUs -> cacerts/localhost-10054-  | TLS 90 days / enrollment 6 months        | gencrl, distribute CRL to organizations/peerOrganizations/   |
|   MSP)         | CA: ca_consortiumops:10054    |    ca-consortiumops.pem              |                                           | consortiumops.../msp/crls/, restart peer0/users              |
| Vault: vault/  | Vault: rendered/consortiumops |                                      |                                           |                                                              |
| rendered/cons. |                               |                                      |                                           |                                                              |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
| RegulatorObs.  | Domain: regulatorobserver...  | Client, Peer (observer), Admin,      | CA: 720h                                 | fabric-ca-client revoke --caname ca-regulatorobserver ...    |
| (RegulatorObs  | MSP: RegulatorObserverMSP     | NodeOUs -> cacerts/localhost-11054-  | TLS 90 days / enrollment 6 months        | gencrl, copy CRL to organizations/peerOrganizations/         |
|   MSP)         | CA: ca_regulatorobserver:     |    ca-regulatorobserver.pem          |                                           | regulatorobserver.../msp/crls/, restart observer peer/users  |
| Vault: vault/  |   11054                       |                                      |                                           |                                                              |
| rendered/reg.. | Vault: rendered/regulatorobs  |                                      |                                           |                                                              |
+----------------+-------------------------------+--------------------------------------+-------------------------------------------+--------------------------------------------------------------+
```

**Sources**: `orgs.yaml`, `fabric-dev-network/organizations/*/msp/config.yaml`, `docs/security/cert-lifecycle.md`, `fabric-dev-network/infra/README.md`.

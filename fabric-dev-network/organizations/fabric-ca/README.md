# Fabric CA Identity Management

This directory contains Fabric CA server configurations and enrollment scripts for all organizations in the AML AI Network.

## When Identities Need Re-Enrollment

**All previously issued MSP identities become invalid** when:

1. **CA databases are reset** (e.g., `fabric-ca-server.db` files are deleted)
   - This happens automatically when running `./network.sh down` (unless using `-r` restart mode)
   - Manual deletion of `organizations/fabric-ca/*/fabric-ca-server.db` files
   - Vault key rotation that requires CA stack recreation

2. **CA certificates are rotated** (new CA key/cert pair generated)

3. **CA containers are recreated** after a database reset

## Re-Enrollment Methods

After a CA database reset, choose one of these methods to regenerate MSP material:

### Option 1: Network Bring-Up Script (Recommended)
```bash
cd fabric-dev-network
./network.sh up createChannel -ca -c <channel-name> -s couchdb
```
This automatically:
- Starts CA containers
- Enrolls CA admins
- Registers and enrolls all peer/orderer/user identities
- Generates TLS certificates
- Creates the channel and joins peers

### Option 2: Manual Enrollment Script
```bash
cd fabric-dev-network
./organizations/fabric-ca/registerEnroll.sh all
```
Or enroll specific organizations:
```bash
./organizations/fabric-ca/registerEnroll.sh banka
./organizations/fabric-ca/registerEnroll.sh bankb
./organizations/fabric-ca/registerEnroll.sh consortiumops
./organizations/fabric-ca/registerEnroll.sh regulator
./organizations/fabric-ca/registerEnroll.sh orderer
```

### Option 3: Individual TLS Renewal
For renewing TLS certificates only (when MSP material still exists):
```bash
cd fabric-dev-network
./scripts/certs/renew_tls.sh -c <component-name>
```

## Verification

After re-enrollment, verify identities are valid:

```bash
# Check peer can list channels
export PATH=${PWD}/fabric-samples/bin:${PATH}
. scripts/envVar.sh
setGlobals 1  # BankA
peer channel list

# Verify CA can list certificates
FABRIC_CA_CLIENT_HOME=organizations/peerOrganizations/banka.example.com \
  ./fabric-samples/bin/fabric-ca-client certificate list \
  --caname ca-banka \
  --tls.certfiles organizations/fabric-ca/banka/ca-cert.pem
```

## Related Documentation

- `fabric-dev-network/infra/README.md` - Evidence log with CA reset notices
- `docs/security/cert-lifecycle.md` - Certificate lifecycle and renewal procedures
- `scripts/certs/renew_tls.sh` - TLS certificate renewal automation


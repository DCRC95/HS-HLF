# Access-Control Matrix – Fabric Roles vs Permissions

| MSP Role / Identity Class | Channel Access | Chaincode Actions | Config Mgmt / Governance | Event / Log Visibility | Notes |
|---------------------------|----------------|-------------------|--------------------------|------------------------|-------|
| **BankAMSP Admin** (`organizations/peerOrganizations/banka.example.com/users/Admin@...`) | `model-governance`, `sar-audit`, `ops-monitoring` | Approve/commit chaincode definitions, invoke/query all consortium chaincodes | Can create/join channels, set anchor peers, approve channel updates, manage ACLs for BankA; participates in endorsement policy decisions | Full peer/orderer logs for BankA; access to consortium observability dashboards | Must co-sign config changes per governance policy; holds `hf.Registrar` attributes for CA ops. |
| **BankAMSP Peer** (`peer0/peer1.banka...`) | `model-governance`, `sar-audit` | Endorse chaincode per policy (e.g., `ContributionLedger`, `SARAnchor`), host state DB | No direct config rights; receives updates pushed by admins | Emits block/chaincode events; metrics scraped by Prometheus | Peer identities are used by CLI via `CORE_PEER_MSPCONFIGPATH`. |
| **BankAMSP Client/User** (`User1@banka`, app identities) | `model-governance`, `sar-audit` (per ACL) | Invoke/query chaincodes allowed to BankA (e.g., submit contributions, pull SAR metadata) | None | Subscribes to events via Fabric Gateway; limited log access through app telemetry | Cannot alter channel config; must use approved SDK flows. |
| **BankBMSP Admin** | Same as BankA for BankB | Same as BankA | Same as BankA for BankB org | Similar observability scope limited to BankB assets | Follows identical governance rules. |
| **BankBMSP Peer** | `model-governance`, `sar-audit` | Endorse per policy | None | Emits events/metrics for BankB |  |
| **BankBMSP Client/User** | `model-governance`, `sar-audit` (per ACL) | Invoke/query allowed chaincodes | None | Event access via SDK |  |
| **ConsortiumOps Admin** (`Admin@consortiumops`) | All channels (`model-governance`, `sar-audit`, `ops-monitoring`) | Deploy/upgrade shared chaincode packages, run operational chaincode (e.g., governance checks) | Can coordinate channel creation, anchor peer updates, CI/CD approvals; manage monitoring configs | Full access to ops dashboards/logs | Acts as platform operator; coordinates multi-org actions per steering committee approvals. |
| **ConsortiumOps Peer** (`peer0.consortiumops`) | Typically hosts `ops-monitoring` + read-only participation on other channels if needed | Runs operations chaincodes/observers; may endorse if policy includes ConsortiumOps | No config rights unless explicitly delegated | Emits ops metrics/logs |  |
| **ConsortiumOps Client/User** | Access based on service role (e.g., monitoring agents) | Limited to operational chaincodes (health checks, governance automation) | None | Observability tooling |  |
| **RegulatorObserver Admin** (`Admin@regulatorobserver`) | `sar-audit` (primary), optional read-only on `model-governance` | Read-only chaincode queries (e.g., fetch SAR anchors, acknowledgements) | Cannot modify config; can request updates via governance | Access to regulator dashboards, audit logs, filtered events | Serves as liaison with supervisory bodies. |
| **RegulatorObserver Peer** (`peer0.regulatorobserver`) | `sar-audit` channel (joined as reader) | Does not endorse; participates as ledger replica for audit | No config rights | Provides read-only block/event stream to regulator apps | Anchor peer status optional. |
| **RegulatorObserver Client/User** (observer apps) | `sar-audit` read-only | Query `SARAnchor` chaincode, fetch metadata/hashes | None | Limited to filtered events/logs | No write access; ensures compliance with SAR confidentiality. |
| **OrdererMSP Admin** (`Admin@orderer`) | System channel + all application channels | None (ordering service only) | Manage orderer nodes, genesis/channel creation, consensus config | Full orderer logs/metrics | Coords RAFT operations; no chaincode-level actions. |
| **Orderer Node Identity** (`orderer.orderer.example.com`) | All channels for ordering | None | Runs consensus, delivers blocks | Orderer metrics/logs | Trust anchor for block delivery. |

## Channel / Chaincode Policy Summary
- `model-governance`: Members – BankA, BankB, ConsortiumOps. Endorsement: `AND('BankAMSP.peer','BankBMSP.peer')` (exact policy TBD). Admin rights: respective org admins + ConsortiumOps.
- `sar-audit`: Members – BankA, BankB, RegulatorObserver. Endorsement for `SARAnchor`: banks write, regulator read-only; policy restricts writes to banks, reads to all members.
- `ops-monitoring`: Primarily ConsortiumOps; other orgs may subscribe read-only for transparency.

## Usage Notes
- ACLs (fabric `ACLs:` in `configtx.yaml`) map Fabric roles to chaincode/system functions; ensure they reflect this matrix.
- Update this matrix whenever endorsement policies or channel membership changes.

# Phase 2 — Blockchain Integration Plan

> **Status:** In Progress. Phase 1 (API-free scanner) is complete.
> Smart contract, Dart service, and UI integration implemented. Awaiting deployment decisions.

## Goal

Add **tamper-proof, publicly-verifiable halal certification & provenance** so
users can trust that a product's / venue's halal status hasn't been silently
altered. Blockchain is used for **trust and auditability**, not for OCR or
ingredient lookup (those stay offline/free per Phase 1).

## Recommended Feature: On-Chain Halal Certificate Registry

- Certification bodies issue halal certificates. Instead of trusting a mutable
  Firestore `isVerified` flag, store an **immutable record on-chain**:
  `productId → certificateHash → certifier → issuedAt → expiresAt`.
- Anchor the admin venue **approve/deny** workflow on-chain too, so every
  verification decision becomes an immutable public log.
- The app reads the chain and shows a **"Blockchain Verified"** badge.

## Proposed Stack

| Concern | Choice |
|---------|--------|
| Chain | **Polygon** (low gas, EVM). Develop on **Amoy testnet** (free). |
| Smart contract | Solidity `HalalRegistry` (store/verify cert records). |
| Flutter client | `web3dart` (mature, maintained) over JSON-RPC. |
| Optional | Thirdweb for managed wallet/contract infra. |

## Cost Model

- **Reads** (user verification) are free.
- **Writes** (admin issuing/anchoring certs) cost tiny gas — user scans never
  cost money.

## Data Flow (Phase 2)

```
Scan → Phase-1 engine → AnalysisResult
                        │
                        └─► (optional) query HalalRegistry on-chain
                              → "Blockchain Verified" badge + audit trail
```

## Implementation Status

### ✅ Completed
- `contracts/HalalRegistry.sol` — Solidity contract with `issueCertificate`, `revokeCertificate`, `verifyCertificate`, `isCertifier`
- `lib/services/blockchain_config.dart` — Feature flag, RPC URL, contract address, chain ID
- `lib/services/blockchain_service.dart` — Read-only Web3 client, `verifyCertificateByBarcode()`, pure-Dart keccak256
- `lib/screens/scanner_screen.dart` — Blockchain check after barcode lookup, "Blockchain Verified" badge, API info entry
- `lib/screens/admin_screen.dart` — Blockchain registry status card in Tools tab
- `test/blockchain_test.dart` — Unit tests for result logic, config, keccak256 test vectors
- `pubspec.yaml` — Added `web3dart: ^2.7.3`
- `CHANGELOG.md` — Phase 2 section added

### 🔲 Remaining (Deployment Decisions Needed)
1. Deploy `HalalRegistry` to Polygon Amoy testnet → update `contractAddress` in `blockchain_config.dart`
2. Replace demo RPC URL with production Infura/Alchemy/QuickNode endpoint
3. Set up backend Cloud Function for certificate writes (no private keys in app)
4. Add certifier addresses via `addCertifier()` (owner only)
5. Choose: Polygon mainnet vs. Amoy testnet for production

## Guardrails

- Keep blockchain **behind a feature flag**; the core scanner must never depend
  on chain availability.
- Do not put private keys in the mobile app — admin writes should be relayed
  through a backend (e.g., Cloud Function) holding the wallet.

## Open Decisions (to confirm before building)

1. Public chain (Polygon mainnet) vs. private/permissioned chain?
2. Who are the "certifier" identities allowed to write? (access control)
3. Wallet/key custody for admin writes (Thirdweb vs. custom backend signer)?
4. Should venue verification also be mirrored, or only product certs?

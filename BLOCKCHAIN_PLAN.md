# Phase 2 — Blockchain Integration Plan (Deferred)

> **Status:** Not yet implemented. Phase 1 (API-free scanner) is complete.
> This document captures the agreed design so Phase 2 can start without
> re-planning.

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

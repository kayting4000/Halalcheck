/// Blockchain configuration for the on-chain halal certificate registry.
///
/// Phase 2: Read-only on-chain verification. The Flutter app only reads from
/// the chain — write operations (issuing/revoking certificates) are performed
/// by authorized certifiers through a backend relay (e.g., Cloud Function),
/// never from the mobile app.
///
/// Set [enabled] to false to fall back to Phase 1 offline analysis only.
class BlockchainConfig {
  /// Whether blockchain verification is enabled (feature flag).
  static const bool enabled = true;

  /// Polygon Amoy testnet RPC endpoint.
  /// Replace with your own Infura/Alchemy/QuickNode endpoint for production.
  static const String rpcUrl = 'https://polygon-amoy.g.alchemy.com/v2/demo';

  /// Deployed HalalRegistry contract address (checksummed).
  /// Set after contract deployment; empty means "not yet deployed".
  static const String contractAddress = '';

  /// Chain ID for Polygon Amoy testnet.
  static const int chainId = 80002;

  /// Product ID namespace prefix — used to derive a deterministic bytes32
  /// productId from a barcode: keccak256("halal:barcode:<barcode>").
  static const String productIdNamespace = 'halal:barcode';
}

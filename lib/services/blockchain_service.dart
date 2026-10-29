import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:http/http.dart' as http;
import 'blockchain_config.dart';

/// Result of an on-chain certificate verification.
class BlockchainVerificationResult {
  final bool isValid;
  final String? certificateHash;
  final String? certifier;
  final DateTime? expiresAt;
  final bool blockchainEnabled;
  final String? error;

  BlockchainVerificationResult({
    required this.isValid,
    this.certificateHash,
    this.certifier,
    this.expiresAt,
    required this.blockchainEnabled,
    this.error,
  });

  /// Whether the UI should display a "Blockchain Verified" badge.
  bool get showBadge => blockchainEnabled && isValid && error == null;
}

/// Read-only on-chain halal certificate verification service.
///
/// Queries the deployed [HalalRegistry] smart contract on Polygon Amoy.
/// No private keys are stored — this client only performs public reads.
class BlockchainService {
  const BlockchainService._();

  static Web3Client? _client;
  static DeployedContract? _contract;
  static ContractFunction? _verifyFn;

  /// Initialize the Web3 client and load the contract ABI.
  /// Safe to call multiple times; subsequent calls are no-ops.
  static Future<void> init() async {
    if (!BlockchainConfig.enabled) return;
    if (_client != null) return;

    try {
      final httpClient = http.Client();
      _client = Web3Client(BlockchainConfig.rpcUrl, httpClient);

      final abiJson = jsonDecode(_contractAbi) as List<dynamic>;
      final contractAddress =
          EthereumAddress.fromHex(BlockchainConfig.contractAddress);

      _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(abiJson), 'HalalRegistry'),
        contractAddress,
      );

      _verifyFn = _contract!.function('verifyCertificate');
    } catch (e) {
      if (kDebugMode) {
        print('BlockchainService init failed: $e');
      }
      _client = null;
      _contract = null;
      _verifyFn = null;
    }
  }

  /// Verify whether a product has a valid on-chain halal certificate.
  ///
  /// Derives a deterministic productId from the barcode and queries the
  /// [HalalRegistry.verifyCertificate] function.
  ///
  /// Returns [BlockchainVerificationResult] with [isValid] = false if
  /// blockchain is disabled, the contract is not deployed, or the query fails.
  static Future<BlockchainVerificationResult> verifyCertificateByBarcode(
    String barcode,
  ) async {
    if (!BlockchainConfig.enabled) {
      return BlockchainVerificationResult(
        isValid: false,
        blockchainEnabled: false,
      );
    }

    if (_client == null || _verifyFn == null || _contract == null) {
      await init();
    }

    if (_client == null || _verifyFn == null || _contract == null) {
      return BlockchainVerificationResult(
        isValid: false,
        blockchainEnabled: true,
        error: 'Blockchain client not initialized',
      );
    }

    final productId = _deriveProductId(barcode);

    try {
      final result = await _client!.call(
        contract: _contract!,
        function: _verifyFn!,
        params: [productId],
      );

      final isValid = result[0] as bool;
      final certHashBytes = result[1] as List<int>;
      final certifierAddr = result[2] as EthereumAddress;
      final expiresAtBigInt = result[3] as BigInt;

      final certificateHash =
          certHashBytes.isNotEmpty ? '0x${bytesToHex(certHashBytes)}' : null;
      final certifier = certifierAddr.hex;
      final expiresAt =
          expiresAtBigInt > BigInt.zero
              ? DateTime.fromMillisecondsSinceEpoch(
                  expiresAtBigInt.toInt() * 1000,
                )
              : null;

      return BlockchainVerificationResult(
        isValid: isValid,
        certificateHash: certificateHash,
        certifier: certifier,
        expiresAt: expiresAt,
        blockchainEnabled: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Blockchain verification failed: $e');
      }
      return BlockchainVerificationResult(
        isValid: false,
        blockchainEnabled: true,
        error: e.toString(),
      );
    }
  }

  /// Derive a deterministic bytes32 productId from a barcode:
  /// keccak256("halal:barcode:<barcode>")
  static Uint8List _deriveProductId(String barcode) {
    return keccakUtf8('${BlockchainConfig.productIdNamespace}:$barcode');
  }

  /// Dispose the HTTP client.
  static Future<void> dispose() async {
    _client?.dispose();
    _client = null;
    _contract = null;
    _verifyFn = null;
  }
}

/// Contract ABI for HalalRegistry (only the verifyCertificate function).
/// This is the JSON ABI produced by the Solidity compiler.
const String _contractAbi = '''
[
  {
    "inputs": [
      {
        "internalType": "bytes32",
        "name": "productId",
        "type": "bytes32"
      }
    ],
    "name": "verifyCertificate",
    "outputs": [
      {
        "internalType": "bool",
        "name": "isValid",
        "type": "bool"
      },
      {
        "internalType": "bytes32",
        "name": "certHash",
        "type": "bytes32"
      },
      {
        "internalType": "address",
        "name": "certifier",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "expiresAt",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "isCertifier",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
''';

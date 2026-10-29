import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/crypto.dart';
import 'package:halal_scanner/services/blockchain_service.dart';
import 'package:halal_scanner/services/blockchain_config.dart';

void main() {
  group('BlockchainVerificationResult', () {
    test('showBadge is true only when enabled, valid, and no error', () {
      final r = BlockchainVerificationResult(
        isValid: true,
        certificateHash: '0x1234',
        certifier: '0xabcd',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        blockchainEnabled: true,
      );
      expect(r.showBadge, isTrue);
    });

    test('showBadge is false when blockchain disabled', () {
      final r = BlockchainVerificationResult(
        isValid: true,
        blockchainEnabled: false,
      );
      expect(r.showBadge, isFalse);
    });

    test('showBadge is false when invalid', () {
      final r = BlockchainVerificationResult(
        isValid: false,
        blockchainEnabled: true,
      );
      expect(r.showBadge, isFalse);
    });

    test('showBadge is false when error present', () {
      final r = BlockchainVerificationResult(
        isValid: true,
        blockchainEnabled: true,
        error: 'Connection failed',
      );
      expect(r.showBadge, isFalse);
    });
  });

  group('BlockchainConfig', () {
    test('enabled defaults to true', () {
      expect(BlockchainConfig.enabled, isTrue);
    });

    test('chainId is Polygon Amoy (80002)', () {
      expect(BlockchainConfig.chainId, 80002);
    });

    test('productIdNamespace is set', () {
      expect(BlockchainConfig.productIdNamespace, isNotEmpty);
    });
  });

  group('keccak256', () {
    test('produces deterministic 32-byte output', () {
      final h1 = keccak256(Uint8List.fromList(utf8.encode('test')));
      final h2 = keccak256(Uint8List.fromList(utf8.encode('test')));
      expect(h1, h2);
      expect(h1.length, 32);
    });

    test('different inputs produce different hashes', () {
      final h1 = keccak256(Uint8List.fromList(utf8.encode('hello')));
      final h2 = keccak256(Uint8List.fromList(utf8.encode('world')));
      expect(h1, isNot(h2));
    });

    test('empty input produces known keccak256', () {
      // keccak256("") = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
      final h = keccak256(Uint8List(0));
      final hex = bytesToHex(h);
      expect(hex, 'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470');
    });

    test('known Ethereum keccak256 test vector', () {
      final input = Uint8List.fromList(utf8.encode('hello world'));
      final h = keccak256(input);
      final hex = bytesToHex(h);
      expect(hex, '47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad');
    });
  });

  group('_deriveProductId', () {
    test('derives deterministic productId from barcode', () {
      final input1 = Uint8List.fromList(utf8.encode('halal:barcode:1234567890128'));
      final h1 = keccak256(input1);
      final input2 = Uint8List.fromList(utf8.encode('halal:barcode:1234567890128'));
      final h2 = keccak256(input2);
      expect(h1, h2);
      expect(h1.length, 32);
    });

    test('different barcodes produce different productIds', () {
      final h1 = keccak256(Uint8List.fromList(utf8.encode('halal:barcode:111')));
      final h2 = keccak256(Uint8List.fromList(utf8.encode('halal:barcode:222')));
      expect(h1, isNot(h2));
    });
  });
}

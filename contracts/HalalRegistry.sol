// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title HalalRegistry
 * @dev On-chain halal certificate registry for tamper-proof verification.
 *
 * Certification bodies issue halal certificates that are anchored immutably
 * on-chain. The mobile app performs read-only queries to display a
 * "Blockchain Verified" badge. Write access is restricted to certifier
 * addresses and should be relayed through a backend (e.g., Cloud Function)
 * — private keys must never be embedded in the mobile app.
 */
contract HalalRegistry {
    event CertificateIssued(
        bytes32 indexed productId,
        bytes32 indexed certificateHash,
        address indexed certifier,
        uint256 issuedAt,
        uint256 expiresAt
    );

    event CertificateRevoked(bytes32 indexed productId, address indexed certifier);

    // Mapping: productId => certificate data
    struct Certificate {
        bytes32 certificateHash;
        address certifier;
        uint256 issuedAt;
        uint256 expiresAt;
        bool revoked;
    }

    mapping(bytes32 => Certificate) public certificates;

    // Set of authorized certifier addresses
    mapping(address => bool) public certifiers;

    address public owner;

    modifier onlyCertifier() {
        require(certifiers[msg.sender], "Not an authorized certifier");
        _;
    }

    constructor() {
        owner = msg.sender;
        certifiers[owner] = true;
    }

    /**
     * @dev Authorize a new certifier address (owner only).
     */
    function addCertifier(address newCertifier) external {
        require(msg.sender == owner, "Only owner");
        certifiers[newCertifier] = true;
    }

    /**
     * @dev Revoke a certifier address (owner only).
     */
    function removeCertifier(address oldCertifier) external {
        require(msg.sender == owner, "Only owner");
        require(oldCertifier != owner, "Cannot remove owner");
        certifiers[oldCertifier] = false;
    }

    /**
     * @dev Issue or update a halal certificate for a product.
     * @param productId      Unique identifier for the product (e.g., keccak256(barcode))
     * @param certificateHash Hash of the off-chain certificate document
     * @param expiresAt      Unix timestamp when the certificate expires
     */
    function issueCertificate(
        bytes32 productId,
        bytes32 certificateHash,
        uint256 expiresAt
    ) external onlyCertifier {
        require(!certificates[productId].revoked, "Certificate revoked");
        require(expiresAt > block.timestamp, "Expiry must be in the future");

        certificates[productId] = Certificate({
            certificateHash: certificateHash,
            certifier: msg.sender,
            issuedAt: block.timestamp,
            expiresAt: expiresAt,
            revoked: false
        });

        emit CertificateIssued(productId, certificateHash, msg.sender, block.timestamp, expiresAt);
    }

    /**
     * @dev Revoke a certificate (certifier only).
     */
    function revokeCertificate(bytes32 productId) external onlyCertifier {
        require(certificates[productId].certifier == msg.sender, "Not the issuing certifier");
        require(!certificates[productId].revoked, "Already revoked");

        certificates[productId].revoked = true;
        emit CertificateRevoked(productId, msg.sender);
    }

    /**
     * @dev Check if a product has a valid, non-revoked, non-expired certificate.
     * @return isValid   True if certificate exists, is not revoked, and not expired
     * @return certHash  The certificate hash (empty if none)
     * @return certifier The certifier address (zero if none)
     * @return expiresAt Expiry timestamp (zero if none)
     */
    function verifyCertificate(bytes32 productId)
        external
        view
        returns (bool isValid, bytes32 certHash, address certifier, uint256 expiresAt)
    {
        Certificate storage cert = certificates[productId];
        isValid = !cert.revoked && cert.certificateHash != bytes32(0) && cert.expiresAt > block.timestamp;
        certHash = cert.certificateHash;
        certifier = cert.certifier;
        expiresAt = cert.expiresAt;
    }

    /**
     * @dev Check if an address is an authorized certifier.
     */
    function isCertifier(address addr) external view returns (bool) {
        return certifiers[addr];
    }
}
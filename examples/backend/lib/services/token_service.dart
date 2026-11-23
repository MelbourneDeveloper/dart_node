import 'dart:convert';

import 'package:nadz/nadz.dart';
import 'package:shared/models/user.dart';

/// Token verification error types
sealed class TokenError {
  const TokenError();

  String get message;
}

/// Token format is invalid (missing parts)
class InvalidFormat extends TokenError {
  const InvalidFormat();

  @override
  String get message => 'Invalid token format';
}

/// Token signature doesn't match
class InvalidSignature extends TokenError {
  const InvalidSignature();

  @override
  String get message => 'Invalid token signature';
}

/// Token has expired
class TokenExpired extends TokenError {
  const TokenExpired();

  @override
  String get message => 'Token has expired';
}

/// Token payload could not be decoded
class CorruptedPayload extends TokenError {
  const CorruptedPayload();

  @override
  String get message => 'Corrupted token payload';
}

/// Simple JWT-like token service
/// In production, use a proper JWT library!
class TokenService {
  /// Creates token service with signing secret
  TokenService(this._secret);

  final String _secret;

  /// Generate a token for a user ID
  String generate(String userId) {
    final payload = {
      'userId': userId,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'exp': DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch,
    };

    // Simple base64 encoding (NOT secure - just for demo)
    final payloadJson = jsonEncode(payload);
    final signature = _sign(payloadJson);

    return '${base64Encode(utf8.encode(payloadJson))}.$signature';
  }

  /// Verify and decode a token
  Result<TokenPayload, TokenError> verify(String token) {
    final parts = token.split('.');
    if (parts.length != 2) {
      return const Error(InvalidFormat());
    }

    // Decode payload
    final String payloadJson;
    try {
      payloadJson = utf8.decode(base64Decode(parts[0]));
    } on Object {
      return const Error(CorruptedPayload());
    }

    // Verify signature
    final expectedSig = _sign(payloadJson);
    if (parts[1] != expectedSig) {
      return const Error(InvalidSignature());
    }

    // Parse payload
    final Object? decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on Object {
      return const Error(CorruptedPayload());
    }

    if (decoded is! Map<String, dynamic>) {
      return const Error(CorruptedPayload());
    }
    final payload = decoded;

    // Check expiration
    final expValue = payload['exp'];
    if (expValue is! int) {
      return const Error(CorruptedPayload());
    }
    if (DateTime.now().millisecondsSinceEpoch > expValue) {
      return const Error(TokenExpired());
    }

    // Extract fields
    final userIdValue = payload['userId'];
    if (userIdValue is! String) {
      return const Error(CorruptedPayload());
    }

    final iatValue = payload['iat'];
    if (iatValue is! int) {
      return const Error(CorruptedPayload());
    }

    return Success((
      userId: userIdValue,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(iatValue),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expValue),
    ));
  }

  String _sign(String data) =>
      // Super simple "signature" - NOT SECURE, just for demo
      base64Encode(utf8.encode('$data$_secret')).substring(0, 32);
}
